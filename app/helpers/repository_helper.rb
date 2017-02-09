module RepositoryHelper
  def access_levels_options
    {
      push_access_levels: ProtectedBranch::PushAccessLevel.human_access_levels.map { |id, text| { id: id, text: text } },
      merge_access_levels: ProtectedBranch::MergeAccessLevel.human_access_levels.map { |id, text| { id: id, text: text } },
      selected_merge_access_levels: @protected_branch.merge_access_levels.map { |access_level| access_level.user_id || access_level.access_level },
      selected_push_access_levels: @protected_branch.push_access_levels.map { |access_level| access_level.user_id || access_level.access_level }
    }
  end

  def load_gon_index
    params = { open_branches: @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } } }
    params.merge!(current_project_id: @project.id) if @project
    gon.push(params.merge(access_levels_options))
  end
end
