# frozen_string_literal: true

module Gitlab
  module Marginalia
    MARGINALIA_FEATURE_FLAG = :marginalia

    def self.set_application_name
      ::Marginalia.application_name = Gitlab.process_name
    end

    def self.enable_sidekiq_instrumentation
      if Sidekiq.server?
        ::Marginalia::SidekiqInstrumentation.enable!
      end
    end

    def self.cached_feature_enabled?
      !!@enabled
    end

    def self.set_feature_cache
      # During db:create and db:bootstrap skip feature query as DB is not available yet.
      return false unless ActiveRecord::Base.connected? && Gitlab::Database.cached_table_exists?('features')

      @enabled = Feature.enabled?(MARGINALIA_FEATURE_FLAG)
    end
  end
end
