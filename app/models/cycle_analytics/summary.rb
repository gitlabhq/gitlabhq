class CycleAnalytics
  class Summary
    def initialize(project, from:)
      @project = project
      @from = from
    end

    def new_issues
      @project.issues.created_after(@from).count
    end

    def commits
      repository = @project.repository.raw_repository

      if @project.default_branch
        repository.log(ref: @project.default_branch, after: @from).count
      end
    end

    def deploys
      @project.deployments.where("created_at > ?", @from).count
    end
  end
end
