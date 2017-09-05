require 'securerandom'

# Compare 2 branches for one repo or between repositories
# and return Gitlab::Git::Compare object that responds to commits and diffs
class CompareService
  attr_reader :start_project, :start_branch_name

  def initialize(new_start_project, new_start_branch_name)
    @start_project = new_start_project
    @start_branch_name = new_start_branch_name
  end

  def execute(target_project, target_branch, straight: false)
    raw_compare = target_project.repository.compare_source_branch(target_branch, start_project.repository, start_branch_name, straight: straight)

    Compare.new(raw_compare, target_project, straight: straight) if raw_compare
  end
end
