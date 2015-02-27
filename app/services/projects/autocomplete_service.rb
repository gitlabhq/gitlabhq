module Projects
  class AutocompleteService < BaseService
    def initialize(project)
      @project = project
    end

    def issues
      @project.issues.opened.select([:iid, :title])
    end

    def merge_requests
      @project.merge_requests.opened.select([:iid, :title])
    end
  end
end
