# frozen_string_literal: true

module Mutations
  module Users
    class SetNamespaceCommitEmail < BaseMutation
      graphql_name 'UserSetNamespaceCommitEmail'

      argument :namespace_id,
        ::Types::GlobalIDType[::Namespace],
        required: true,
        description: 'ID of the namespace to set the namespace commit email for.'

      argument :email_id,
        ::Types::GlobalIDType[::Email],
        required: false,
        description: 'ID of the email to set.'

      field :namespace_commit_email,
        Types::Users::NamespaceCommitEmailType,
        null: true,
        description: 'User namespace commit email after mutation.'

      authorize :read_namespace

      def resolve(args)
        namespace = authorized_find!(args[:namespace_id])
        args[:email_id] = args[:email_id].model_id

        result = ::Users::SetNamespaceCommitEmailService.new(current_user, namespace, args[:email_id], {}).execute
        {
          namespace_commit_email: result.payload[:namespace_commit_email],
          errors: result.errors
        }
      end

      private

      def find_object(id)
        GitlabSchema.object_from_id(
          id, expected_type: [::Namespace, ::Namespaces::UserNamespace, ::Namespaces::ProjectNamespace]).sync
      end
    end
  end
end
