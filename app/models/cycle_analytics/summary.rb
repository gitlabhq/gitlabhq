class CycleAnalytics
  class Summary
    def initialize(project, from:)
      @project = project
      @from = from
    end

    def new_issues
      @project.issues.where("created_at > ?", @from).count
    end

    def commits
      repository = @project.repository.raw_repository
      repository.log(ref: @project.default_branch, after: @from).count
    end

    def deploys
      @project.deployments.count
    end
  end
end
