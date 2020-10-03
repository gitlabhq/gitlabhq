# frozen_string_literal: true

module API
  module Entities
    class UserWithAdmin < UserPublic
      expose :admin?, as: :is_admin
      expose :note
    end
  end
end

API::Entities::UserWithAdmin.prepend_if_ee('EE::API::Entities::UserWithAdmin')
