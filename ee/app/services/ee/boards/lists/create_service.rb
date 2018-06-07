module EE
  module Boards
    module Lists
      module CreateService
        extend ::Gitlab::Utils::Override

        override :type
        def type
          return :assignee if params.keys.include?('assignee_id')

          super
        end

        override :target
        def target(board)
          strong_memoize(:target) do
            case type
            when :assignee
              find_user(board)
            else
              super
            end
          end
        end

        def find_user(board)
          user_ids = user_finder(board).execute(include_descendants: true).non_invite.select(:user_id)
          ::User.where(id: user_ids).find(params[:assignee_id])
        end

        def user_finder(board)
          @service ||=
            if board.parent.is_a?(Group)
              GroupMembersFinder.new(board.parent)
            else
              MembersFinder.new(board.parent, current_user)
            end
        end
      end
    end
  end
end
