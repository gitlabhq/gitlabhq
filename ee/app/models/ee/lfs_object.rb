module EE
  # LfsObject EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `LfsObject` model
  module LfsObject
    extend ActiveSupport::Concern

    prepended do
      prepend ::EE::Geo::ForeignDataWrapped
    end
  end
end
