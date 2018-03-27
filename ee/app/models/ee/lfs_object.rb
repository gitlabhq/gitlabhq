module EE
  # LFS Object EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `LfsObject` model
  module LfsObject
    extend ActiveSupport::Concern

    prepended do
      after_destroy :log_geo_event
    end

    private

    def log_geo_event
      ::Geo::LfsObjectDeletedEventStore.new(self).create
    end
  end
end
