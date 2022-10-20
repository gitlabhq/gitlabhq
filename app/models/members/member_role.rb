# frozen_string_literal: true

class MemberRole < ApplicationRecord  # rubocop:disable Gitlab/NamespacedClass
  has_many :members
  belongs_to :namespace

  validates :namespace, presence: true
  validates :base_access_level, presence: true
  validate :belongs_to_top_level_namespace

  private

  def belongs_to_top_level_namespace
    return if !namespace || namespace.root?

    errors.add(:namespace, s_("must be top-level namespace"))
  end
end
