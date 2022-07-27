# frozen_string_literal: true

class MemberRole < ApplicationRecord  # rubocop:disable Gitlab/NamespacedClass
  has_many :members
  belongs_to :namespace

  validates :namespace_id, presence: true
  validates :base_access_level, presence: true
end
