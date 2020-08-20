# frozen_string_literal: true

module Gitlab
  module SidekiqVersioning
    module Worker
      extend ActiveSupport::Concern

      included do
        version 0

        attr_writer :job_version
      end

      class_methods do
        def version(new_version = nil)
          if new_version
            sidekiq_options version: new_version.to_i
          else
            get_sidekiq_options['version']
          end
        end
      end

      # Version is not set if `new.perform` is called directly,
      # and in that case we fallback to latest version
      def job_version
        @job_version ||= self.class.version
      end
    end
  end
end
