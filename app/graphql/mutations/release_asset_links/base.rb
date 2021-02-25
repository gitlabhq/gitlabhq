# frozen_string_literal: true

module Mutations
  module ReleaseAssetLinks
    class Base < BaseMutation
      include FindsProject

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Full path of the project the asset link is associated with.'

      argument :tag_name, GraphQL::STRING_TYPE,
               required: true, as: :tag,
               description: "Name of the associated release's tag."
    end
  end
end
