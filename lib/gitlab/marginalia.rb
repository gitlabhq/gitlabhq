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

    def self.feature_enabled?
      return false unless Gitlab::Database.cached_table_exists?('features')

      Feature.enabled?(MARGINALIA_FEATURE_FLAG)
    end
  end
end
