class CycleAnalytics
  class Summary
    def initialize(project, current_user, from:)
      @project = project
      @current_user = current_user
      @from = from
    end

    def new_issues
      IssuesFinder.new(@current_user, project_id: @project.id).execute.created_after(@from).count
    end

    def commits
      ref = @project.default_branch.presence
      count_commits_for(ref)
    end

    def deploys
      @project.deployments.where("created_at > ?", @from).count
    end

    private

    # Don't use the `Gitlab::Git::Repository#log` method, because it enforces
    # a limit. Since we need a commit count, we _can't_ enforce a limit, so
    # the easiest way forward is to replicate the relevant portions of the
    # `log` function here.
    def count_commits_for(ref)
      return unless ref

      repository = @project.repository.raw_repository
      sha = @project.repository.commit(ref).sha

      cmd = %W(git --git-dir=#{repository.path} log)
      cmd << '--format=%H'
      cmd << "--after=#{@from.iso8601}"
      cmd << sha

      raw_output = IO.popen(cmd) { |io| io.read }
      raw_output.lines.count
    end
  end
end
