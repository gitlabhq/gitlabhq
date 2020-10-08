# frozen_string_literal: true

module Mutations
  module Boards
    class Create < ::Mutations::BaseMutation
      include Mutations::ResolvesGroup
      include ResolvesProject

      graphql_name 'CreateBoard'

      field :board,
            Types::BoardType,
            null: true,
            description: 'The board after mutation.'

      argument :project_path, GraphQL::ID_TYPE,
               required: false,
               description: 'The project full path the board is associated with.'
      argument :group_path, GraphQL::ID_TYPE,
               required: false,
               description: 'The group full path the board is associated with.'
      argument :name,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The board name.'
      argument :assignee_id,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The ID of the user to be assigned to the board.'
      argument :milestone_id,
               GraphQL::ID_TYPE,
               required: false,
               description: 'The ID of the milestone to be assigned to the board.'
      argument :weight,
               GraphQL::BOOLEAN_TYPE,
               required: false,
               description: 'The weight of the board.'
      argument :label_ids,
               [GraphQL::ID_TYPE],
               required: false,
               description: 'The IDs of labels to be added to the board.'

      authorize :admin_board

      def resolve(args)
        group_path = args.delete(:group_path)
        project_path = args.delete(:project_path)

        board_parent = authorized_find!(group_path: group_path, project_path: project_path)
        response = ::Boards::CreateService.new(board_parent, current_user, args).execute

        {
          board: response.payload,
          errors: response.errors
        }
      end

      def ready?(**args)
        if args.values_at(:project_path, :group_path).compact.blank?
          raise Gitlab::Graphql::Errors::ArgumentError,
                'group_path or project_path arguments are required'
        end

        super
      end

      private

      def find_object(group_path: nil, project_path: nil)
        if group_path
          resolve_group(full_path: group_path)
        else
          resolve_project(full_path: project_path)
        end
      end
    end
  end
end
