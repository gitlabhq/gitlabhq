# frozen_string_literal: true

class Organization < ApplicationRecord
  DEFAULT_ORGANIZATION_ID = 1

  scope :without_default, -> { where.not(id: DEFAULT_ORGANIZATION_ID) }

  before_destroy :check_if_default_organization

  validates :name,
    presence: true,
    length: { maximum: 255 },
    uniqueness: { case_sensitive: false }

  def default?
    id == DEFAULT_ORGANIZATION_ID
  end

  private

  def check_if_default_organization
    return unless default?

    raise ActiveRecord::RecordNotDestroyed, _('Cannot delete the default organization')
  end
end
