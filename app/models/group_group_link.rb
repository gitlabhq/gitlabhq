# frozen_string_literal: true

class GroupGroupLink < ActiveRecord::Base
  include Expirable

  belongs_to :shared_group, class_name: 'Group', foreign_key: :shared_group_id
  belongs_to :shared_with_group, class_name: 'Group', foreign_key: :shared_with_group_id

  validates :shared_group, presence: true
  validates :shared_group_id, uniqueness: { scope: [:shared_with_group_id], message: 'already shared with this group' }
  validates :shared_with_group, presence: true
  validates :group_access, presence: true
  validates :group_access, inclusion: { in: Gitlab::Access.values }, presence: true

  def self.access_options
    Gitlab::Access.options
  end

  def self.default_access
    Gitlab::Access::DEVELOPER
  end
end
