# frozen_string_literal: true

require 'flipper/adapters/active_record'
require 'flipper/adapters/active_support_cache_store'

module Feature
  class FlipperRecord < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord -- This class perfectly replaces
    # Flipper::Adapters::ActiveRecord::Model, which inherits ActiveRecord::Base
    include DatabaseReflection
    self.abstract_class = true

    # Bypass the load balancer by restoring the default behavior of `connection`
    # before the load balancer patches ActiveRecord::Base
    def self.connection
      retrieve_connection
    end
  end

  class FlipperFeature < FlipperRecord
    self.table_name = 'features'
  end

  class FlipperGate < FlipperRecord
    self.table_name = 'feature_gates'
  end

  class OptOut
    def initialize(inner)
      @inner = inner
    end

    def flipper_id
      "#{@inner.flipper_id}:opt_out"
    end
  end

  # Generates the same flipper_id when in a request
  # If not in a request, it generates a unique flipper_id every time
  class FlipperRequest
    def flipper_id
      Gitlab::SafeRequestStore.fetch("flipper_request_id") do
        "FlipperRequest:#{SecureRandom.uuid}".freeze
      end
    end
  end

  # Generates the same flipper_id for a given kubernetes pod,
  # or for the entire gitlab application if deployed on a single host.
  class FlipperPod
    attr_reader :flipper_id

    def initialize
      @flipper_id = "FlipperPod:#{Socket.gethostname}".freeze
    end
  end

  # Generates a unique flipper_id for the current GitLab instance.
  class FlipperGitlabInstance
    attr_reader :flipper_id

    def initialize
      @flipper_id = "FlipperGitlabInstance:#{::Gitlab.config.gitlab.host}".freeze
    end
  end

  # To enable EE overrides
  class ActiveSupportCacheStoreAdapter < Flipper::Adapters::ActiveSupportCacheStore
  end

  InvalidFeatureFlagError = Class.new(Exception) # rubocop:disable Lint/InheritException
  InvalidOperation = Class.new(ArgumentError)

  class << self
    delegate :group, to: :flipper

    def all
      flipper.features.to_a
    end

    # Preload the features with the given names.
    #
    # names - An Array of String or Symbol names of the features.
    #
    # https://github.com/flippercloud/flipper/blob/bf6a13f34fc7f45a597c3d66ec291f3e5855e830/lib/flipper/dsl.rb#L229
    def preload(names)
      flipper.preload(names) # rubocop:disable CodeReuse/ActiveRecord -- This cop is not relevant in the Flipper context
    end

    RecursionError = Class.new(RuntimeError)

    def get(key)
      with_feature(key, &:itself)
    end

    def persisted_names
      return [] unless FlipperRecord.database.exists?

      # This loads names of all stored feature flags
      # and returns a stable Set in the following order:
      # - Memoized: using Gitlab::SafeRequestStore or @flipper
      # - L1: using Process cache
      # - L2: using Redis cache
      # - DB: using a single SQL query
      flipper.adapter.features
    end

    def persisted_name?(feature_name)
      # Flipper creates on-memory features when asked for a not-yet-created one.
      # If we want to check if a feature has been actually set, we look for it
      # on the persisted features list.
      persisted_names.include?(feature_name.to_s)
    end

    # The default state of feature flag is read from `YAML`:
    # 1. If feature flag does not have YAML it will fallback to `default_enabled: false`
    #    in production environment, but raise exception in development or tests.
    # 2. The `default_enabled_if_undefined:` is tech debt related to Gitaly flags
    #    and should not be used outside of Gitaly's `lib/feature/gitaly.rb`
    def enabled?(key, thing = nil, type: nil, default_enabled_if_undefined: nil)
      thing = sanitized_thing(thing)

      check_feature_flags_definition!(key, thing, type)

      default_enabled = Feature::Definition.default_enabled?(key, default_enabled_if_undefined: default_enabled_if_undefined)
      feature_value = current_feature_value(key, thing, default_enabled: default_enabled)

      # If not yielded, then either recursion is happening, or the database does not exist yet, so use default_enabled.
      feature_value = default_enabled if feature_value.nil?

      # If we don't filter out this flag here we will enter an infinite loop
      log_feature_flag_state(key, feature_value) if log_feature_flag_states?(key)

      feature_value
    end

    def disabled?(key, thing = nil, type: nil, default_enabled_if_undefined: nil)
      thing = sanitized_thing(thing)

      # we need to make different method calls to make it easy to mock / define expectations in test mode
      thing.nil? ? !enabled?(key, type: type, default_enabled_if_undefined: default_enabled_if_undefined) : !enabled?(key, thing, type: type, default_enabled_if_undefined: default_enabled_if_undefined)
    end

    def enable(key, thing = true)
      thing = sanitized_thing(thing)

      log(key: key, action: __method__, thing: thing)

      return_value = with_feature(key) { _1.enable(thing) }

      # rubocop:disable Gitlab/RailsLogger
      Rails.logger.warn('WARNING: Understand the stability and security risks of enabling in-development features with feature flags.')
      Rails.logger.warn('See https://docs.gitlab.com/ee/administration/feature_flags.html#risks-when-enabling-features-still-in-development for more information.')
      # rubocop:enable Gitlab/RailsLogger

      return_value
    end

    def disable(key, thing = false)
      thing = sanitized_thing(thing)

      log(key: key, action: __method__, thing: thing)

      with_feature(key) { _1.disable(thing) }
    end

    def opted_out?(key, thing)
      thing = sanitized_thing(thing)

      return false unless thing.respond_to?(:flipper_id) # Ignore Feature::Types::Group
      return false unless persisted_name?(key)

      opt_out = OptOut.new(thing)

      with_feature(key) { _1.actors_value.include?(opt_out.flipper_id) }
    end

    def opt_out(key, thing)
      thing = sanitized_thing(thing)

      return unless thing.respond_to?(:flipper_id) # Ignore Feature::Types::Group

      log(key: key, action: __method__, thing: thing)
      opt_out = OptOut.new(thing)

      with_feature(key) { _1.enable(opt_out) }
    end

    def remove_opt_out(key, thing)
      thing = sanitized_thing(thing)

      return unless thing.respond_to?(:flipper_id) # Ignore Feature::Types::Group
      return unless persisted_name?(key)

      log(key: key, action: __method__, thing: thing)
      opt_out = OptOut.new(thing)

      with_feature(key) { _1.disable(opt_out) }
    end

    def enable_percentage_of_time(key, percentage)
      log(key: key, action: __method__, percentage: percentage)
      with_feature(key) do |flag|
        raise InvalidOperation, 'Cannot enable percentage of time for a fully-enabled flag' if flag.state == :on

        flag.enable_percentage_of_time(percentage)
      end
    end

    def disable_percentage_of_time(key)
      log(key: key, action: __method__)
      with_feature(key, &:disable_percentage_of_time)
    end

    def enable_percentage_of_actors(key, percentage)
      log(key: key, action: __method__, percentage: percentage)
      with_feature(key) do |flag|
        raise InvalidOperation, 'Cannot enable percentage of actors for a fully-enabled flag' if flag.state == :on

        flag.enable_percentage_of_actors(percentage)
      end
    end

    def disable_percentage_of_actors(key)
      log(key: key, action: __method__)
      with_feature(key, &:disable_percentage_of_actors)
    end

    def remove(key)
      return unless persisted_name?(key)

      log(key: key, action: __method__)

      with_feature(key, &:remove)
    end

    def reset
      Gitlab::SafeRequestStore.delete(:flipper) if Gitlab::SafeRequestStore.active?
      @flipper = nil
    end

    # This method is called from config/initializers/0_inject_feature_flags.rb and can be used
    # to register Flipper groups.
    # See https://docs.gitlab.com/ee/development/feature_flags/index.html
    #
    # EE feature groups should go inside the ee/lib/ee/feature.rb version of this method.
    def register_feature_groups; end

    def register_definitions
      Feature::Definition.reload!
    end

    def register_hot_reloader
      return unless check_feature_flags_definition?

      Feature::Definition.register_hot_reloader!
    end

    def current_request
      if Gitlab::SafeRequestStore.active?
        Gitlab::SafeRequestStore[:flipper_request] ||= FlipperRequest.new
      else
        @flipper_request ||= FlipperRequest.new
      end
    end

    def current_pod
      @flipper_pod ||= FlipperPod.new
    end

    def gitlab_instance
      @flipper_gitlab_instance ||= FlipperGitlabInstance.new
    end

    def logger
      @logger ||= Feature::Logger.build
    end

    def log_feature_flag_states?(key)
      Feature::Definition.log_states?(key)
    end

    def log_feature_flag_state(key, feature_value)
      logged_states[key] ||= feature_value
    end

    def logged_states
      RequestStore.fetch(:feature_flag_events) { {} }
    end

    # rubocop: disable CodeReuse/ActiveRecord -- rubocop doesn't recognize Flipper::Adapters::ActiveRecord::Gate as ActiveRecord.
    def group_ids_for(feature_key)
      FlipperGate.where(feature_key: feature_key)
                 .pluck(:value)
                 .select { |v| v.start_with?("Group:") }
                 .map { |v| v.sub("Group:", "") }
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def sanitized_thing(thing)
      case thing
      when :instance
        gitlab_instance
      when :request, :current_request
        current_request
      when :pod, :current_pod
        current_pod
      else
        thing
      end
    end

    # Compute if thing is enabled, taking opt-out overrides into account
    # Evaluate if `default enabled: false` or the feature has been persisted.
    # `persisted_name?` can potentially generate DB queries and also checks for inclusion
    # in an array of feature names (177 at last count), possibly reducing performance by half.
    # So we only perform the `persisted` check if `default_enabled: true`
    def current_feature_value(key, thing, default_enabled:)
      with_feature(key) do |feature|
        if default_enabled && !Feature.persisted_name?(feature.name)
          true
        else
          enabled = feature.enabled?(thing)

          if enabled && !thing.nil?
            opt_out = OptOut.new(thing)
            feature.actors_value.exclude?(opt_out.flipper_id)
          else
            enabled
          end
        end
      end
    end

    # NOTE: it is not safe to call `Flipper::Feature#enabled?` outside the block
    def with_feature(key)
      feature = unsafe_get(key)
      yield feature if feature.present?
    ensure
      pop_recursion_stack
    end

    def unsafe_get(key)
      # During setup the database does not exist yet. So we haven't stored a value
      # for the feature yet and return the default.

      return unless FlipperRecord.database.exists?

      flag_stack = ::Thread.current[:feature_flag_recursion_check] || []
      Thread.current[:feature_flag_recursion_check] = flag_stack

      # Prevent more than 10 levels of recursion. This limit was chosen as a fairly
      # low limit while allowing some nesting of flag evaluation. We have not seen
      # this limit hit in production.
      if flag_stack.size > 10
        Gitlab::ErrorTracking.track_exception(RecursionError.new('deep recursion'), stack: flag_stack)
        return
      elsif flag_stack.include?(key)
        Gitlab::ErrorTracking.track_exception(RecursionError.new('self recursion'), stack: flag_stack)
        return
      end

      flag_stack.push(key)
      flipper.feature(key)
    end

    def pop_recursion_stack
      flag_stack = Thread.current[:feature_flag_recursion_check]
      flag_stack.pop if flag_stack
    end

    def flipper
      if Gitlab::SafeRequestStore.active?
        Gitlab::SafeRequestStore[:flipper] ||= build_flipper_instance(memoize: true)
      else
        @flipper ||= build_flipper_instance
      end
    end

    def build_flipper_instance(memoize: false)
      active_record_adapter = Flipper::Adapters::ActiveRecord.new(
        feature_class: FlipperFeature,
        gate_class: FlipperGate)
      # Redis L2 cache
      redis_cache_adapter =
        ActiveSupportCacheStoreAdapter.new(
          active_record_adapter,
          l2_cache_backend,
          expires_in: 1.hour,
          write_through: true)

      # Thread-local L1 cache: use a short timeout since we don't have a
      # way to expire this cache all at once
      flipper_adapter = Flipper::Adapters::ActiveSupportCacheStore.new(
        redis_cache_adapter,
        l1_cache_backend,
        expires_in: 1.minute)

      Flipper.new(flipper_adapter).tap do |flip|
        flip.memoize = memoize
      end
    end

    def check_feature_flags_definition?
      # We want to check feature flags usage only when
      # running in development or test environment
      Gitlab.dev_or_test_env?
    end

    def check_feature_flags_definition!(key, thing, type)
      return unless check_feature_flags_definition?

      if thing && !thing.respond_to?(:flipper_id) && !thing.is_a?(Flipper::Types::Group)
        raise InvalidFeatureFlagError,
          "The thing '#{thing.class.name}' for feature flag '#{key}' needs to include `FeatureGate` or implement `flipper_id`"
      end

      Feature::Definition.valid_usage!(key, type: type)
    end

    def l1_cache_backend
      Gitlab::ProcessMemoryCache.cache_backend
    end

    def l2_cache_backend
      ::Gitlab::Redis::FeatureFlag.cache_store
    end

    def log(key:, action:, **extra)
      extra ||= {}
      extra = extra.transform_keys { |k| "extra.#{k}" }
      extra = extra.transform_values { |v| v.respond_to?(:flipper_id) ? v.flipper_id : v }
      extra = extra.transform_values(&:to_s)
      logger.info(key: key, action: action, **extra)
    end
  end

  class Target
    UnknownTargetError = Class.new(StandardError)

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def gate_specified?
      %i[user project group feature_group namespace repository].any? { |key| params.key?(key) }
    end

    def targets
      [feature_group, users, projects, groups, namespaces, repositories].flatten.compact
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def feature_group
      return unless params.key?(:feature_group)

      Feature.group(params[:feature_group])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def users
      return unless params.key?(:user)

      params[:user].split(',').map do |arg|
        UserFinder.new(arg).find_by_username || (raise UnknownTargetError, "#{arg} is not found!")
      end
    end

    def projects
      return unless params.key?(:project)

      params[:project].split(',').map do |arg|
        Project.find_by_full_path(arg) || (raise UnknownTargetError, "#{arg} is not found!")
      end
    end

    def groups
      return unless params.key?(:group)

      params[:group].split(',').map do |arg|
        Group.find_by_full_path(arg) || (raise UnknownTargetError, "#{arg} is not found!")
      end
    end

    def namespaces
      return unless params.key?(:namespace)

      params[:namespace].split(',').map do |arg|
        # We are interested in Group or UserNamespace
        Namespace.without_project_namespaces.find_by_full_path(arg) || (raise UnknownTargetError, "#{arg} is not found!")
      end
    end

    def repositories
      return unless params.key?(:repository)

      params[:repository].split(',').map do |arg|
        container, _project, _type, _path = Gitlab::RepoPath.parse(arg)
        raise UnknownTargetError, "#{arg} is not found!" if container.nil?

        container.repository
      end
    end
  end
end

Feature.prepend_mod
Feature::ActiveSupportCacheStoreAdapter.prepend_mod_with('Feature::ActiveSupportCacheStoreAdapter')
