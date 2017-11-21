module EE
  module Ci
    # Build EE mixin
    #
    # This module is intended to encapsulate EE-specific model logic
    # and be included in the `Build` model
    module Build
      extend ActiveSupport::Concern

      included do
        scope :codequality, ->() { where(name: %w[codequality codeclimate]) }
        scope :sast, ->() { where(name: 'sast') }

        after_save :stick_build_if_status_changed
      end

      def shared_runners_minutes_limit_enabled?
        runner && runner.shared? && project.shared_runners_minutes_limit_enabled?
      end

      def stick_build_if_status_changed
        return unless status_changed?
        return unless running?

        ::Gitlab::Database::LoadBalancing::Sticking.stick(:build, id)
      end

      def has_codeclimate_json?
        options.dig(:artifacts, :paths) == ['codeclimate.json'] &&
          artifacts_metadata?
      end

      def has_sast_json?
        options.dig(:artifacts, :paths) == ['gl-sast-report.json'] &&
          artifacts_metadata?
      end
    end
  end
end
