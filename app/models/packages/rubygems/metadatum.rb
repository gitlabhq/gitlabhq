# frozen_string_literal: true

module Packages
  module Rubygems
    class Metadatum < ApplicationRecord
      self.primary_key = :package_id

      belongs_to :package, class_name: 'Packages::Rubygems::Package', inverse_of: :rubygems_metadatum

      validates :package, presence: true
    end
  end
end
