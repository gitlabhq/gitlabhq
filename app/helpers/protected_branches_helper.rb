module ProtectedBranchesHelper
  def access_levels_options
    {
      push_access_levels: ProtectedBranch::PushAccessLevel.human_access_levels.map { |id, text| { id: id, text: text, before_divider: true } },
      merge_access_levels: ProtectedBranch::MergeAccessLevel.human_access_levels.map { |id, text| { id: id, text: text, before_divider: true } }
    }
  end

  def load_gon_index(project)
    params = { open_branches: project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } } }
    gon.push(params.merge(access_levels_options))
  end
end
