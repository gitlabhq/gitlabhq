# frozen_string_literal: true

require 'flipper/adapters/active_record'
require 'flipper/adapters/active_support_cache_store'

class Feature
  prepend_if_ee('EE::Feature') # rubocop: disable Cop/InjectEnterpriseEditionModule

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

  class << self
    delegate :group, to: :flipper

    def all
      flipper.features.to_a
    end

    def get(key)
      flipper.feature(key)
    end

    def persisted_names
      Gitlab::SafeRequestStore[:flipper_persisted_names] ||=
        begin
          # We saw on GitLab.com, this database request was called 2300
          # times/s. Let's cache it for a minute to avoid that load.
          Gitlab::ThreadMemoryCache.cache_backend.fetch('flipper:persisted_names', expires_in: 1.minute) do
            FlipperFeature.feature_names
          end
        end
    end

    def persisted?(feature)
      # Flipper creates on-memory features when asked for a not-yet-created one.
      # If we want to check if a feature has been actually set, we look for it
      # on the persisted features list.
      persisted_names.include?(feature.name.to_s)
    end

    # use `default_enabled: true` to default the flag to being `enabled`
    # unless set explicitly.  The default is `disabled`
    def enabled?(key, thing = nil, default_enabled: false)
      # During setup the database does not exist yet. So we haven't stored a value
      # for the feature yet and return the default.
      return default_enabled unless Gitlab::Database.exists?

      feature = Feature.get(key)

      # If we're not default enabling the flag or the feature has been set, always evaluate.
      # `persisted?` can potentially generate DB queries and also checks for inclusion
      # in an array of feature names (177 at last count), possibly reducing performance by half.
      # So we only perform the `persisted` check if `default_enabled: true`
      !default_enabled || Feature.persisted?(feature) ? feature.enabled?(thing) : true
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

    def remove(key)
      feature = get(key)
      return unless persisted?(feature)

      feature.remove
    end

    def flipper
      if Gitlab::SafeRequestStore.active?
        Gitlab::SafeRequestStore[:flipper] ||= build_flipper_instance
      else
        @flipper ||= build_flipper_instance
      end
    end

    def build_flipper_instance
      Flipper.new(flipper_adapter).tap { |flip| flip.memoize = true }
    end

    # This method is called from config/initializers/flipper.rb and can be used
    # to register Flipper groups.
    # See https://docs.gitlab.com/ee/development/feature_flags.html#feature-groups
    def register_feature_groups
    end

    def flipper_adapter
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
      Flipper::Adapters::ActiveSupportCacheStore.new(
        redis_cache_adapter,
        l1_cache_backend,
        expires_in: 1.minute)
    end

    def l1_cache_backend
      Gitlab::ThreadMemoryCache.cache_backend
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
