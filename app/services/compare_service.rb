require 'securerandom'

# Compare 2 branches for one repo or between repositories
# and return Gitlab::Git::Compare object that responds to commits and diffs
class CompareService
  attr_reader :base_project, :base_branch_name

  def initialize(new_base_project, new_base_branch_name)
    @base_project = new_base_project
    @base_branch_name = new_base_branch_name
  end

  def execute(target_project, target_branch, straight: false)
    # If compare with other project we need to fetch ref first
    target_project.repository.with_repo_branch_commit(
      base_project.repository,
      base_branch_name) do |commit|
      break unless commit

      compare(commit.sha, target_project, target_branch, straight)
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
