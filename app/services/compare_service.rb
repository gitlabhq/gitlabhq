require 'securerandom'

# Compare 2 branches for one repo or between repositories
# and return Gitlab::Git::Compare object that responds to commits and diffs
class CompareService
  attr_reader :source_project, :source_branch_name

  def initialize(new_source_project, new_source_branch_name)
    @source_project = new_source_project
    @source_branch_name = new_source_branch_name
  end

  def execute(target_project, target_branch, straight: false)
    source_sha = source_project.repository.
      commit(source_branch_name).try(:sha)

    return unless source_sha

    # If compare with other project we need to fetch ref first
    if target_project == source_project
      compare(source_sha, target_project, target_branch, straight)
    else
      target_project.repository.with_tmp_ref(
        source_project.repository, source_branch_name) do
        compare(source_sha, target_project, target_branch, straight)
      end
    end
  end

  private

  def compare(source_sha, target_project, target_branch, straight)
    raw_compare = Gitlab::Git::Compare.new(
      target_project.repository.raw_repository,
      target_branch,
      source_sha,
      straight
    )

    Compare.new(raw_compare, target_project, straight: straight)
  end
end
