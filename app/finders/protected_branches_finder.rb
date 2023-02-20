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

  attr_accessor :project_or_group, :params

  def initialize(project_or_group, params = {})
    @project_or_group = project_or_group
    @params = params
  end

  def execute
    protected_branches = if project_or_group.is_a?(Group)
                           project_or_group.protected_branches
                         else
                           project_or_group.all_protected_branches
                         end

    protected_branches = protected_branches.limit(LIMIT)
    by_name(protected_branches)
  end

  private

  def by_name(protected_branches)
    return protected_branches unless params[:search].present?

    protected_branches.by_name(params[:search])
  end
end
