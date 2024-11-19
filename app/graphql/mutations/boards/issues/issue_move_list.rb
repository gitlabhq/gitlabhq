# frozen_string_literal: true

module Mutations
  module Boards
    module Issues
      class IssueMoveList < Mutations::Issues::Base
        graphql_name 'IssueMoveList'
        BoardGID = ::Types::GlobalIDType[::Board]
        ListID = ::GraphQL::Types::ID
        IssueID = ::GraphQL::Types::ID

        argument :board_id, BoardGID,
          required: true,
          loads: Types::BoardType,
          description: 'Global ID of the board that the issue is in.'

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Project the issue to mutate is in.'

        argument :iid, GraphQL::Types::String,
          required: true,
          description: 'IID of the issue to mutate.'

        argument :from_list_id, ListID,
          required: false,
          description: 'ID of the board list that the issue will be moved from.'

        argument :to_list_id, ListID,
          required: false,
          description: 'ID of the board list that the issue will be moved to.'

        argument :move_before_id, IssueID,
          required: false,
          description: 'ID of issue that should be placed before the current issue.'

        argument :move_after_id, IssueID,
          required: false,
          description: 'ID of issue that should be placed after the current issue.'

        argument :position_in_list, GraphQL::Types::Int,
          required: false,
          description: "Position of issue within the board list. Positions start at 0. " \
            "Use #{::Boards::Issues::MoveService::LIST_END_POSITION} to move to the end of the list."

        def ready?(**args)
          if move_arguments(args).blank?
            raise Gitlab::Graphql::Errors::ArgumentError,
              'At least one of the arguments ' \
                'fromListId, toListId, positionInList, moveAfterId, or moveBeforeId is required'
          end

          if move_list_arguments(args).one?
            raise Gitlab::Graphql::Errors::ArgumentError,
              'Both fromListId and toListId must be present'
          end

          if args[:position_in_list].present?
            if move_list_arguments(args).empty?
              raise Gitlab::Graphql::Errors::ArgumentError,
                'Both fromListId and toListId are required when positionInList is given'
            end

            if args[:move_before_id].present? || args[:move_after_id].present?
              raise Gitlab::Graphql::Errors::ArgumentError,
                'positionInList is mutually exclusive with any of moveBeforeId or moveAfterId'
            end

            if args[:position_in_list] != ::Boards::Issues::MoveService::LIST_END_POSITION &&
                args[:position_in_list] < 0
              raise Gitlab::Graphql::Errors::ArgumentError,
                "positionInList must be >= 0 or #{::Boards::Issues::MoveService::LIST_END_POSITION}"
            end
          end

          super
        end

        def resolve(board:, project_path:, iid:, **args)
          issue = authorized_find!(project_path: project_path, iid: iid)
          move_params = { id: issue.id, board_id: board.id }.merge(move_arguments(args))

          result = move_issue(board, issue, move_params)

          {
            issue: issue.reset,
            errors: error_for(result)
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
          args.slice(:from_list_id, :to_list_id, :position_in_list, :move_after_id, :move_before_id)
        end

        def error_for(result)
          return [] unless result.error?

          [result.message]
        end
      end
    end
  end
end

Mutations::Boards::Issues::IssueMoveList.prepend_mod_with('Mutations::Boards::Issues::IssueMoveList')
