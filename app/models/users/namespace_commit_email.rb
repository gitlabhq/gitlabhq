# frozen_string_literal: true

module Users
  class NamespaceCommitEmail < ApplicationRecord
    belongs_to :user
    belongs_to :namespace
    belongs_to :email

    validates :user, presence: true
    validates :namespace, presence: true
    validates :email, presence: true
    validates :user_id, uniqueness: { scope: [:namespace_id] }
  end
end
