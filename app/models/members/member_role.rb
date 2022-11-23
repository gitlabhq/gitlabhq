# frozen_string_literal: true

class MemberRole < ApplicationRecord  # rubocop:disable Gitlab/NamespacedClass
  has_many :members
  belongs_to :namespace

  validates :namespace, presence: true
  validates :base_access_level, presence: true
  validate :belongs_to_top_level_namespace
  validate :validate_namespace_locked, on: :update

  validates_associated :members

  private

  def belongs_to_top_level_namespace
    return if !namespace || namespace.root?

    errors.add(:namespace, s_("MemberRole|must be top-level namespace"))
  end

  def validate_namespace_locked
    return unless namespace_id_changed?

    errors.add(:namespace, s_("MemberRole|can't be changed"))
  end
end
