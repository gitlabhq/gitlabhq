# frozen_string_literal: true

# This class represents a software license policy. Which means the fact that the user
# approves or not of the use of a certain software license in their project.
# For use in the License Management feature.
class SoftwareLicensePolicy < ActiveRecord::Base
  include Presentable

  # Only allows modification of the approval status
  FORM_EDITABLE = %i[approval_status].freeze

  belongs_to :project, inverse_of: :software_license_policies
  belongs_to :software_license, -> { readonly }
  attr_readonly :software_license

  # Licenses must be approved or blacklisted.
  enum approval_status: {
      blacklisted: 0,
      approved: 1
  }

  # Software license is mandatory, it contains the license informations.
  validates_associated :software_license
  validates_presence_of :software_license

  validates_presence_of :project
  validates :approval_status, presence: true

  # A license is unique for its project since it can't be approved and blacklisted.
  validates :software_license, uniqueness: { scope: :project_id }

  scope :ordered, -> { SoftwareLicensePolicy.includes(:software_license).order("software_licenses.name ASC") }

  def name
    software_license.name
  end
end
