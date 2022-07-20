# frozen_string_literal: true

module API
  module Entities
    class DeployKey < Entities::SSHKey
      expose :key
      expose :fingerprint, if: ->(key, _) { key.fingerprint.present? }
      expose :fingerprint_sha256

      expose :projects_with_write_access, using: Entities::ProjectIdentity, if: -> (_, options) { options[:include_projects_with_write_access] }
    end
  end
end
