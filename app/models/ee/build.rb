module EE
  # Build EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Build` model
  module Build
    extend ActiveSupport::Concern

    def shared_runners_minutes_quota?
      runner && runner.shared? && project.shared_runners_minutes_quota?
    end
  end
end
