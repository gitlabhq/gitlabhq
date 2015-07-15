# Compare 2 branches for one repo or between repositories
# and return Gitlab::CompareResult object that responds to commits and diffs
class CompareService
  def execute(current_user, source_project, source_branch, target_project, target_branch)
    # Try to compare branches to get commits list and diffs
    if target_project == source_project
      Gitlab::CompareResult.new(
        Gitlab::Git::Compare.new(
          target_project.repository.raw_repository,
          target_branch,
          source_branch,
        )
      )
    else
      raise 'Implement me'
    end
  end
end
