# frozen_string_literal: true
class ProtectedEnvironment < ActiveRecord::Base
  include ::Gitlab::Utils::StrongMemoize

  belongs_to :project
  has_many :deploy_access_levels, inverse_of: :protected_environment

  accepts_nested_attributes_for :deploy_access_levels, allow_destroy: true

  validates :deploy_access_levels, length: { minimum: 1 }
  validates :name, :project, presence: true

  def accessible_to?(user)
    deploy_access_levels
      .any? { |deploy_access_level| deploy_access_level.check_access(user) }
  end
end
