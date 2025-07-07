# frozen_string_literal: true

module Mutations
  module Namespaces
    class RegenerateNewWorkItemEmailAddress < BaseMutation
      graphql_name 'NamespacesRegenerateNewWorkItemEmailAddress'
      include ResolvesNamespace

      argument :full_path, GraphQL::Types::ID,
        required: true,
        description: 'Full path of the namespace to regenerate the new work item email address for.'

      field :namespace,
        Types::NamespaceType,
        null: true,
        description: 'Namespace after regenerating the new work item email address.'

      authorize :read_namespace

      def resolve(full_path:)
        namespace = authorized_find!(full_path)

        unless namespace.is_a?(::Namespaces::ProjectNamespace)
          return { namespace: nil, errors: [_('Work item creation via email is only supported for projects')] }
        end

        unless Gitlab::Email::IncomingEmail.supports_work_item_creation?
          return { namespace: nil, errors: [_('Work item creation via email is not supported')] }
        end

        return { namespace: namespace, errors: [] } if current_user.reset_incoming_email_token!

        { namespace: nil, errors: [_('Failed to regenerate new work item email address')] }
      end

      private

      def find_object(full_path)
        resolve_namespace(full_path: full_path)
      end
    end
  end
end
