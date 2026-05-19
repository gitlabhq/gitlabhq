# frozen_string_literal: true

module API
  module Entities
    class GpgCommitSignature < Grape::Entity
      expose :verification_status, documentation: { type: 'String', example: 'verified' }
      expose :gpg_key_id, documentation: { type: 'Integer', example: 1 }
      expose :gpg_key_primary_keyid, documentation: { type: 'String', example: '8254AAB3FBD54AC9' }
      expose :gpg_key_user_name, documentation: { type: 'String', example: 'John Doe' }
      expose :gpg_key_user_email, documentation: { type: 'String', example: 'johndoe@example.com' }
      expose :gpg_key_subkey_id, documentation: { type: 'Integer', example: 1 }
    end
  end
end
