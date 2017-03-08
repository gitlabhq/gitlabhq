module EE
  # Build EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Build` model
  module Build
    extend ActiveSupport::Concern

    def shared_runners_minutes_limit_enabled?
      runner && runner.shared? && project.shared_runners_minutes_limit_enabled?
    end
  end
end
