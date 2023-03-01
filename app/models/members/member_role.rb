# frozen_string_literal: true

class MemberRole < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass
  include IgnorableColumns
  ignore_column :download_code, remove_with: '15.9', remove_after: '2023-01-22'

  MAX_COUNT_PER_GROUP_HIERARCHY = 10

  has_many :members
  belongs_to :namespace

  validates :namespace, presence: true
  validates :base_access_level, presence: true
  validate :belongs_to_top_level_namespace
  validate :max_count_per_group_hierarchy, on: :create
  validate :validate_namespace_locked, on: :update
  validate :attributes_locked_after_member_associated, on: :update

  validates_associated :members

  before_destroy :prevent_delete_after_member_associated

  private

  def belongs_to_top_level_namespace
    return if !namespace || namespace.root?

    errors.add(:namespace, s_("MemberRole|must be top-level namespace"))
  end

  def max_count_per_group_hierarchy
    return unless namespace
    return if namespace.member_roles.count < MAX_COUNT_PER_GROUP_HIERARCHY

    errors.add(:namespace, s_("MemberRole|maximum number of Member Roles are already in use by the group hierarchy. "\
                              "Please delete an existing Member Role."))
  end

  def validate_namespace_locked
    return unless namespace_id_changed?

    errors.add(:namespace, s_("MemberRole|can't be changed"))
  end

  def attributes_locked_after_member_associated
    return unless members.present?

    errors.add(:base, s_("MemberRole|cannot be changed because it is already assigned to a user. "\
      "Please create a new Member Role instead"))
  end

  def prevent_delete_after_member_associated
    return unless members.present?

    errors.add(:base, s_("MemberRole|cannot be deleted because it is already assigned to a user. "\
      "Please disassociate the member role from all users before deletion."))

    throw :abort # rubocop:disable Cop/BanCatchThrow
  end
end
