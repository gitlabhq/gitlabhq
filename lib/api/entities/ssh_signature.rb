# frozen_string_literal: true

module API
  module Entities
    class SshSignature < Grape::Entity
      expose :verification_status, documentation: { type: 'String', example: 'unverified' }
      expose :key, using: ::API::Entities::SSHKey
    end
  end
end
