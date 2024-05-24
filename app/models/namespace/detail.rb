# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- TODO refactor to use bounded context
class Namespace::Detail < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_details
  belongs_to :creator, class_name: "User", optional: true
  validates :namespace, presence: true
  validates :description, length: { maximum: 255 }

  self.primary_key = :namespace_id

  def add_creator(user)
    update_attribute(:creator, user)
  end
end
# rubocop:enable Gitlab/BoundedContexts

Namespace::Detail.prepend_mod
