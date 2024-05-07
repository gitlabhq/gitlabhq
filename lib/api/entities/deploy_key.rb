# frozen_string_literal: true

module API
  module Entities
    class DeployKey < Entities::SSHKey
      expose :key,
        documentation: { type: 'string', example: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==' }

      expose :fingerprint,
        documentation: { type: 'string', example: '4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9' },
        if: ->(key, _) { key.fingerprint.present? }

      expose :fingerprint_sha256,
        documentation: { type: 'string', example: 'SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU' }

      expose :projects_with_write_access, using: Entities::ProjectIdentity, if: ->(_, options) { options[:include_projects_with_write_access] }
      expose :projects_with_readonly_access, using: Entities::ProjectIdentity, if: ->(_, options) { options[:include_projects_with_readonly_access] }
    end
  end
end
