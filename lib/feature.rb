# frozen_string_literal: true

require 'flipper/adapters/active_record'
require 'flipper/adapters/active_support_cache_store'

class Feature
  # Classes to override flipper table names
  class FlipperFeature < Flipper::Adapters::ActiveRecord::Feature
    # Using `self.table_name` won't work. ActiveRecord bug?
    superclass.table_name = 'features'

    def self.feature_names
      pluck(:key)
    end
  end

  class FlipperGate < Flipper::Adapters::ActiveRecord::Gate
    superclass.table_name = 'feature_gates'
  end

  InvalidFeatureFlagError = Class.new(Exception) # rubocop:disable Lint/InheritException

  class << self
    delegate :group, to: :flipper

    def all
      flipper.features.to_a
    end

    def get(key)
      flipper.feature(key)
    end

    def persisted_names
      return [] unless Gitlab::Database.exists?

      if Gitlab::Utils.to_boolean(ENV['FF_LEGACY_PERSISTED_NAMES'])
        # To be removed:
        # This uses a legacy persisted names that are know to work (always)
        Gitlab::SafeRequestStore[:flipper_persisted_names] ||=
          begin
            # We saw on GitLab.com, this database request was called 2300
            # times/s. Let's cache it for a minute to avoid that load.
            Gitlab::ProcessMemoryCache.cache_backend.fetch('flipper:persisted_names', expires_in: 1.minute) do
              FlipperFeature.feature_names
            end.to_set
          end
      else
        # This loads names of all stored feature flags
        # and returns a stable Set in the following order:
        # - Memoized: using Gitlab::SafeRequestStore or @flipper
        # - L1: using Process cache
        # - L2: using Redis cache
        # - DB: using a single SQL query
        flipper.adapter.features
      end
    end

    def persisted_name?(feature_name)
      # Flipper creates on-memory features when asked for a not-yet-created one.
      # If we want to check if a feature has been actually set, we look for it
      # on the persisted features list.
      persisted_names.include?(feature_name.to_s)
    end

    # use `default_enabled: true` to default the flag to being `enabled`
    # unless set explicitly.  The default is `disabled`
    # TODO: remove the `default_enabled:` and read it from the `defintion_yaml`
    # check: https://gitlab.com/gitlab-org/gitlab/-/issues/30228
    def enabled?(key, thing = nil, default_enabled: false)
      if check_feature_flags_definition?
        if thing && !thing.respond_to?(:flipper_id)
          raise InvalidFeatureFlagError,
            "The thing '#{thing.class.name}' for feature flag '#{key}' needs to include `FeatureGate` or implement `flipper_id`"
        end
      end

      # During setup the database does not exist yet. So we haven't stored a value
      # for the feature yet and return the default.
      return default_enabled unless Gitlab::Database.exists?

      feature = get(key)

      # If we're not default enabling the flag or the feature has been set, always evaluate.
      # `persisted?` can potentially generate DB queries and also checks for inclusion
      # in an array of feature names (177 at last count), possibly reducing performance by half.
      # So we only perform the `persisted` check if `default_enabled: true`
      !default_enabled || Feature.persisted_name?(feature.name) ? feature.enabled?(thing) : true
    end

    def disabled?(key, thing = nil, default_enabled: false)
      # we need to make different method calls to make it easy to mock / define expectations in test mode
      thing.nil? ? !enabled?(key, default_enabled: default_enabled) : !enabled?(key, thing, default_enabled: default_enabled)
    end

    def enable(key, thing = true)
      get(key).enable(thing)
    end

    def disable(key, thing = false)
      get(key).disable(thing)
    end

    def enable_group(key, group)
      get(key).enable_group(group)
    end

    def disable_group(key, group)
      get(key).disable_group(group)
    end

    def enable_percentage_of_time(key, percentage)
      get(key).enable_percentage_of_time(percentage)
    end

    def disable_percentage_of_time(key)
      get(key).disable_percentage_of_time
    end

    def enable_percentage_of_actors(key, percentage)
      get(key).enable_percentage_of_actors(percentage)
    end

    def disable_percentage_of_actors(key)
      get(key).disable_percentage_of_actors
    end

    def remove(key)
      return unless persisted_name?(key)

      get(key).remove
    end

    def reset
      Gitlab::SafeRequestStore.delete(:flipper) if Gitlab::SafeRequestStore.active?
      @flipper = nil
    end

    # This method is called from config/initializers/flipper.rb and can be used
    # to register Flipper groups.
    # See https://docs.gitlab.com/ee/development/feature_flags.html#feature-groups
    def register_feature_groups
    end

    private

    def flipper
      if Gitlab::SafeRequestStore.active?
        Gitlab::SafeRequestStore[:flipper] ||= build_flipper_instance
      else
        @flipper ||= build_flipper_instance
      end
    end

    def build_flipper_instance
      active_record_adapter = Flipper::Adapters::ActiveRecord.new(
        feature_class: FlipperFeature,
        gate_class: FlipperGate)

      # Redis L2 cache
      redis_cache_adapter =
        Flipper::Adapters::ActiveSupportCacheStore.new(
          active_record_adapter,
          l2_cache_backend,
          expires_in: 1.hour)

      # Thread-local L1 cache: use a short timeout since we don't have a
      # way to expire this cache all at once
      flipper_adapter = Flipper::Adapters::ActiveSupportCacheStore.new(
        redis_cache_adapter,
        l1_cache_backend,
        expires_in: 1.minute)

      Flipper.new(flipper_adapter).tap do |flip|
        flip.memoize = true
      end
    end

    def check_feature_flags_definition?
      # We want to check feature flags usage only when
      # running in development or test environment
      Gitlab.dev_or_test_env?
    end

    def l1_cache_backend
      Gitlab::ProcessMemoryCache.cache_backend
    end

    def l2_cache_backend
      Rails.cache
    end
  end

  class Target
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def gate_specified?
      %i(user project group feature_group).any? { |key| params.key?(key) }
    end

    def targets
      [feature_group, user, project, group].compact
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def feature_group
      return unless params.key?(:feature_group)

      Feature.group(params[:feature_group])
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def user
      return unless params.key?(:user)

      UserFinder.new(params[:user]).find_by_username!
    end

    def project
      return unless params.key?(:project)

      Project.find_by_full_path(params[:project])
    end

    def group
      return unless params.key?(:group)

      Group.find_by_full_path(params[:group])
    end
  end
end

Feature.prepend_if_ee('EE::Feature')
