# frozen_string_literal: true

module Organizations
  class Organization < ApplicationRecord
    DEFAULT_ORGANIZATION_ID = 1

    scope :without_default, -> { where.not(id: DEFAULT_ORGANIZATION_ID) }

    before_destroy :check_if_default_organization

    has_many :namespaces
    has_many :groups

    has_one :settings, class_name: "OrganizationSetting"

    has_many :organization_users, inverse_of: :organization
    has_many :users, through: :organization_users, inverse_of: :organizations

    validates :name,
      presence: true,
      length: { maximum: 255 }

    validates :path,
      presence: true,
      'organizations/path': true,
      length: { minimum: 2, maximum: 255 }

    def self.default_organization
      find_by(id: DEFAULT_ORGANIZATION_ID)
    end

    def default?
      id == DEFAULT_ORGANIZATION_ID
    end

    def to_param
      path
    end

    def user?(user)
      organization_users.exists?(user: user)
    end

    private

    def check_if_default_organization
      return unless default?

      raise ActiveRecord::RecordNotDestroyed, _('Cannot delete the default organization')
    end
  end
end
