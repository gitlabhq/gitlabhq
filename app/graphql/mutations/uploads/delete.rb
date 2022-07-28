# frozen_string_literal: true

module Mutations
  module Uploads
    class Delete < BaseMutation
      graphql_name 'UploadDelete'
      description 'Deletes an upload.'

      include Mutations::ResolvesResourceParent

      authorize :destroy_upload

      argument :secret, GraphQL::Types::String,
               required: true,
               description: 'Secret part of upload path.'

      argument :filename, GraphQL::Types::String,
               required: true,
               description: 'Upload filename.'

      field :upload, Types::UploadType,
            null: true,
            description: 'Deleted upload.'

      def resolve(args)
        parent = authorized_resource_parent_find!(args)

        result = ::Uploads::DestroyService.new(parent, current_user).execute(args[:secret], args[:filename])

        {
          upload: result[:status] == :success ? result[:upload] : nil,
          errors: Array(result[:message])
        }
      end
    end
  end
end
