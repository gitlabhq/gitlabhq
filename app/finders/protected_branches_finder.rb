# frozen_string_literal: true

# ProtectedBranchesFinder
#
# Used to filter protected branches by set of params
#
# Arguments:
#   project - which project to scope to
#   params:
#     search: string
class ProtectedBranchesFinder
  LIMIT = 100

  attr_accessor :project, :params

  def initialize(project, params = {})
    @project = project
    @params = params
  end

  def execute
    protected_branches = project.limited_protected_branches(LIMIT)
    by_name(protected_branches)
  end

  private

  def by_name(protected_branches)
    return protected_branches unless params[:search].present?

    protected_branches.by_name(params[:search])
  end
end
