# Compare 2 branches for one repo or between repositories
# and return Gitlab::CompareResult object that responds to commits and diffs
class CompareService
  def execute(current_user, source_project, source_branch, target_project, target_branch)
    # Try to compare branches to get commits list and diffs
    #
    # Note: Use satellite only when need to compare between to repos
    # because satellites are slower then operations on bare repo
    if target_project == source_project
      Gitlab::CompareResult.new(
        Gitlab::Git::Compare.new(
          target_project.repository.raw_repository,
          target_branch,
          source_branch,
        )
      )
    else
      Gitlab::Satellite::CompareAction.new(
        current_user,
        target_project,
        target_branch,
        source_project,
        source_branch
      ).result
    end
  end
end
