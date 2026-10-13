# frozen_string_literal: true

module API
  module Entities
    class SshCertificate < Grape::Entity
      expose :id, documentation: { type: 'Integer', format: 'int64', example: 142 }
      expose :title, documentation: { type: 'String', example: 'new ssh cert' }
      expose :key, documentation: { type: 'String' }
      expose :fingerprint, documentation: {
        type: 'String',
        desc: 'SHA256 fingerprint of the SSH certificate authority public key',
        example: 'SHA256:1CrrRznEotAVn+wfXVzYlDCaVcGoTvHIup4eNWBPK2k'
      } do |certificate|
        Gitlab::SSHPublicKey.with_sha256_prefix(certificate.fingerprint)
      end
      expose :created_at, documentation: { type: 'DateTime', example: "2022-01-31T15:10:45.080Z" }
    end
  end
end
