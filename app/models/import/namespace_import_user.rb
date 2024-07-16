# frozen_string_literal: true

module Import
  class NamespaceImportUser < ApplicationRecord
    self.table_name = 'namespace_import_users'

    belongs_to :import_user, class_name: 'User', foreign_key: :user_id, inverse_of: :namespace_import_user
    belongs_to :namespace

    validates :namespace_id, :user_id, presence: true
  end
end
