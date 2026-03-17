# frozen_string_literal: true

module Mutations
  module Labels # rubocop:disable Gitlab/BoundedContexts -- should be moved together with create mutation
    class Update < BaseMutation
      graphql_name 'LabelUpdate'

      field :label,
        Types::LabelType,
        null: true,
        description: 'Label after mutation.'

      argument :id, Types::GlobalIDType[::Label],
        required: true,
        description: 'Global ID of the label to update.'

      argument :archived, GraphQL::Types::Boolean,
        required: false,
        description: 'Whether to archive the label. Introduced in GitLab 18.10.'

      authorize :admin_label

      def resolve(id:, **args)
        label = Gitlab::Graphql::Lazy.force(find_object(id))
        raise_resource_not_available_error! unless label

        unless label.instance_of?(ProjectLabel) || label.instance_of?(GroupLabel)
          raise_resource_not_available_error!('Label is not a project or group label.')
        end

        authorize!(label)

        updated_label = ::Labels::UpdateService.new(args).execute(label)

        {
          label: updated_label.valid? ? updated_label : nil,
          errors: errors_on_object(updated_label)
        }
      end

      private

      def find_object(id)
        GitlabSchema.object_from_id(id, expected_type: ::Label)
      end
    end
  end
end
