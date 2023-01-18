# frozen_string_literal: true

module Users
  class NamespaceCommitEmail < ApplicationRecord
    belongs_to :user
    belongs_to :namespace
    belongs_to :email

    validates :user, presence: true
    validates :namespace, presence: true
    validates :email, presence: true
    validates :user, uniqueness: { scope: :namespace_id }
    validate :validate_root_group

    def self.delete_for_namespace(namespace)
      where(namespace: namespace).delete_all
    end

    private

    def validate_root_group
      # Due to the way Rails validations are invoked all at once,
      # namespace sometimes won't exist when this is ran even though we have a validation for presence first.
      return unless namespace&.group_namespace?
      return if namespace.root?

      errors.add(:namespace, _('must be a root group.'))
    end
  end
end
