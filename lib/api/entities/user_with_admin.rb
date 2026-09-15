# frozen_string_literal: true

module API
  module Entities
    class UserWithAdmin < UserPublic
      expose :admin?, as: :is_admin
      expose :note
      expose :namespace_id
      expose :provisioned_by_project_id
      expose :created_by, with: UserBasic
    end
  end
end

API::Entities::UserWithAdmin.prepend_mod_with('API::Entities::UserWithAdmin')
