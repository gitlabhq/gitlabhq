# frozen_string_literal: true

# This class represents a software license.
# For use in the License Management feature.
class SoftwareLicense < ActiveRecord::Base
  include Presentable

  validates :name, presence: true

  scope :ordered, -> { order(:name) }
end
