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
        experiment: { milestone: '18.4' },
        description: 'Whether the label should be archived. Available only if feature flag `labels_archive` is enabled.'

      authorize :admin_label

      def resolve(id:, **args)
        label = Gitlab::Graphql::Lazy.force(find_object(id))
        raise_resource_not_available_error! unless label

        unless label.instance_of?(ProjectLabel) || label.instance_of?(GroupLabel)
          raise_resource_not_available_error!('Label is not a project or group label.')
        end

        authorize!(label)

        group_actor = label.group || label.project.group
        if args.key?(:archived) && Feature.disabled?(:labels_archive, group_actor)
          raise_resource_not_available_error!("'labels_archive' feature flag is disabled")
        end

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
