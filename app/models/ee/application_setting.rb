module EE
  # ApplicationSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `ApplicationSetting` model
  module ApplicationSetting
    extend ::Prependable

    prepended do
      validates :shared_runners_minutes,
                numericality: { greater_than_or_equal_to: 0 }
    end
  end
end
