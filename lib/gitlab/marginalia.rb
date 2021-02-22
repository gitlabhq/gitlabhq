# frozen_string_literal: true

module Gitlab
  module Marginalia
    def self.set_application_name
      ::Marginalia.application_name = Gitlab.process_name
    end

    def self.enable_sidekiq_instrumentation
      if Sidekiq.server?
        ::Marginalia::SidekiqInstrumentation.enable!
      end
    end
  end
end
