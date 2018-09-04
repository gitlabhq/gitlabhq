module EE
  module API
    module Todos
      extend ActiveSupport::Concern

      prepended do
        helpers do
          # rubocop: disable CodeReuse/ActiveRecord
          def epic
            @epic ||= user_group.epics.find_by(iid: params[:epic_iid])
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def authorize_can_read!
            authorize!(:read_epic, epic)
          end
        end

        resource :groups, requirements: ::API::API::PROJECT_ENDPOINT_REQUIREMENTS do
          desc 'Create a todo on an epic' do
            success ::API::Entities::Todo
          end
          params do
            requires :epic_iid, type: Integer, desc: 'The IID of an epic'
          end
          post ":id/epics/:epic_iid/todo" do
            authorize_can_read!
            todo = ::TodoService.new.mark_todo(epic, current_user).first

            if todo
              present todo, with: ::API::Entities::Todo, current_user: current_user
            else
              not_modified!
            end
          end
        end
      end
    end
  end
end
