module Projects
  class AutocompleteService < BaseService
    def issues
      @project.issues.visible_to_user(current_user).opened.select([:iid, :title])
    end

    def merge_requests
      @project.merge_requests.opened.select([:iid, :title])
    end
  end
end
