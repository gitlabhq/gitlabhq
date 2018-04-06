module EE
  module API
    module Helpers
      module NotesHelpers
        def find_group_epic(id)
          finder_params = { group_id: user_group.id }
          EpicsFinder.new(current_user, finder_params).find(id)
        end

        def noteable_parent_str(noteable_class)
          parent_class = ::Epic <= noteable_class ? ::Group : ::Project

          parent_class.to_s.underscore
        end
      end
    end
  end
end
