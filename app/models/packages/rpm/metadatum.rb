# frozen_string_literal: true

module Packages
  module Rpm
    class Metadatum < ApplicationRecord
      self.primary_key = :package_id

      belongs_to :package, class_name: 'Packages::Rpm::Package', inverse_of: :rpm_metadatum

      validates :package, presence: true
      validates :epoch, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :release, presence: true, length: { maximum: 128 }
      validates :summary, presence: true, length: { maximum: 1000 }
      validates :description, presence: true, length: { maximum: 5000 }
      validates :arch, presence: true, length: { maximum: 255 }
      validates :license, allow_nil: true, length: { maximum: 1000 }
      validates :url, allow_nil: true, length: { maximum: 1000 }
    end
  end
end
