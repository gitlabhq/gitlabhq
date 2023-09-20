# frozen_string_literal: true

require 'securerandom'

# Compare 2 refs for one repo or between repositories
# and return Compare object that responds to commits and diffs
class CompareService
  attr_reader :start_project, :start_ref_name

  def initialize(new_start_project, new_start_ref_name)
    @start_project = new_start_project
    @start_ref_name = new_start_ref_name
  end

  def execute(target_project, target_ref, base_sha: nil, straight: false)
    raw_compare = target_project.repository.compare_source_branch(target_ref, start_project.repository, start_ref_name, straight: straight)

    return unless raw_compare && raw_compare.base && raw_compare.head

    Compare.new(raw_compare, start_project, base_sha: base_sha, straight: straight)
  end
end
