# frozen_string_literal: true

module API
  module Entities
    class SSHKeyWithUser < Entities::SSHKey
      expose :user, using: Entities::UserPublic
    end
  end
end
