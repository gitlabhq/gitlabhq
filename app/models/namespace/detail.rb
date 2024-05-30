# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- TODO refactor to use bounded context
class Namespace::Detail < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_details
  belongs_to :creator, class_name: "User", optional: true
  validates :namespace, presence: true
  validates :description, length: { maximum: 255 }

  self.primary_key = :namespace_id

  # This method should not be called directly. Instead, it is available on the namespace via delegation and should
  # be called after the namespace is saved. Failure to do so will result in errors due to a database trigger that
  # automatically creates the namespace_details after a namespace is created. If we attempt to build the namespace
  # details before the namespace is saved, the trigger will fire and rails will subsequently try to create the
  # namespace_details which will result in an error due to a primary key conflict. Any other modifications to the
  # namespace details should be performed after the associated namespace is saved for the same reason.
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82958/diffs#diff-content-c02244956d423e6837379548e5f9b1fa093bb289
  def add_creator(user)
    update_attribute(:creator, user)
  end
end
# rubocop:enable Gitlab/BoundedContexts

Namespace::Detail.prepend_mod
