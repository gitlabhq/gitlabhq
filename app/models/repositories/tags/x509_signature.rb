# frozen_string_literal: true

module Repositories
  module Tags
    class X509Signature < ApplicationRecord
      include ShaAttribute

      self.table_name = 'tag_x509_signatures'
      enum :verification_status, Enums::CommitSignature.verification_statuses

      belongs_to :project, optional: false
      belongs_to :x509_certificate, optional: false

      sha_attribute :object_name

      validates :object_name, presence: true, uniqueness: { scope: :project_id }
    end
  end
end
