# frozen_string_literal: true

module Repositories
  module Tags
    class SshSignature < ApplicationRecord
      include ShaAttribute
      include SignatureType
      include BulkInsertSafe

      self.table_name = 'tag_ssh_signatures'
      enum :verification_status, Enums::CommitSignature.verification_statuses

      belongs_to :project, optional: false
      belongs_to :key

      sha_attribute :object_name

      validates :object_name, presence: true, uniqueness: { scope: :project_id }

      scope :by_project, ->(project) { where(project:) }
      scope :by_object_name, ->(object_name) { where(object_name:) }

      def type
        :ssh
      end
    end
  end
end
