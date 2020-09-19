# frozen_string_literal: true

module Mutations
  module Boards
    module Issues
      class IssueMoveList < Mutations::Issues::Base
        graphql_name 'IssueMoveList'

        argument :board_id, GraphQL::ID_TYPE,
                  required: true,
                  loads: Types::BoardType,
                  description: 'Global ID of the board that the issue is in'

        argument :project_path, GraphQL::ID_TYPE,
                  required: true,
                  description: 'Project the issue to mutate is in'

        argument :iid, GraphQL::STRING_TYPE,
                  required: true,
                  description: 'IID of the issue to mutate'

        argument :from_list_id, GraphQL::ID_TYPE,
                  required: false,
                  description: 'ID of the board list that the issue will be moved from'

        argument :to_list_id, GraphQL::ID_TYPE,
                  required: false,
                  description: 'ID of the board list that the issue will be moved to'

        argument :move_before_id, GraphQL::ID_TYPE,
                  required: false,
                  description: 'ID of issue that should be placed before the current issue'

        argument :move_after_id, GraphQL::ID_TYPE,
                  required: false,
                  description: 'ID of issue that should be placed after the current issue'

        def ready?(**args)
          if move_arguments(args).blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
                  'At least one of the arguments fromListId, toListId, afterId or beforeId is required'
          end

          if move_list_arguments(args).one?
            raise Gitlab::Graphql::Errors::ArgumentError,
                  'Both fromListId and toListId must be present'
          end

          super
        end

        def resolve(board:, **args)
          Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/-/issues/247861')

          raise_resource_not_available_error! unless board
          authorize_board!(board)

          issue = authorized_find!(project_path: args[:project_path], iid: args[:iid])
          move_params = { id: issue.id, board_id: board.id }.merge(move_arguments(args))

          move_issue(board, issue, move_params)

          {
            issue: issue.reset,
            errors: issue.errors.full_messages
          }
        end

        private

        def move_issue(board, issue, move_params)
          service = ::Boards::Issues::MoveService.new(board.resource_parent, current_user, move_params)

          service.execute(issue)
        end

        def move_list_arguments(args)
          args.slice(:from_list_id, :to_list_id)
        end

        def move_arguments(args)
          args.slice(:from_list_id, :to_list_id, :move_after_id, :move_before_id)
        end

        def authorize_board!(board)
          return if Ability.allowed?(current_user, :read_board, board.resource_parent)

          raise_resource_not_available_error!
        end
      end
    end
  end
end

Mutations::Boards::Issues::IssueMoveList.prepend_if_ee('EE::Mutations::Boards::Issues::IssueMoveList')
