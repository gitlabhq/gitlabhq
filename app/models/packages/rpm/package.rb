# frozen_string_literal: true

module Packages
  module Rpm
    class Package < ::Packages::Package
      self.allow_legacy_sti_class = true

      INSTALLABLE_STATUSES = %i[default hidden].freeze

      has_one :rpm_metadatum, inverse_of: :package, class_name: 'Packages::Rpm::Metadatum'
    end
  end
end
