module Projects
  class AutocompleteService < BaseService
    def issues
      @project.issues.available_for(current_user).opened.select([:iid, :title])
    end

    def merge_requests
      @project.merge_requests.opened.select([:iid, :title])
    end
  end
end
