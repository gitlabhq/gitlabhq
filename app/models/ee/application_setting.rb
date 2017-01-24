module EE
  # ApplicationSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `ApplicationSetting` model
  module ApplicationSetting
    extend ActiveSupport::Concern

    prepended do
      validates :shared_runners_minutes,
                numericality: { greater_than_or_equal_to: 0 }
    end
  end
end
