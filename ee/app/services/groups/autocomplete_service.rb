module Groups
  class AutocompleteService < BaseService
    def epics
      EpicsFinder.new(current_user, group_id: group.id).execute
    end
  end
end
