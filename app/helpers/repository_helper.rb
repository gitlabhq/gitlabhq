module RepositoryHelper
  def access_levels_options
    {
      push_access_levels: ProtectedBranch::PushAccessLevel.human_access_levels.map do |id, text| 
        { id: id, text: text } 
      end,
      merge_access_levels: ProtectedBranch::MergeAccessLevel.human_access_levels.map do |id, text| 
        { id: id, text: text } 
      end,
      selected_merge_access_levels: @protected_branch.merge_access_levels.map do |access_level| 
        access_level.user_id || access_level.access_level 
      end,
      selected_push_access_levels: @protected_branch.push_access_levels.map do |access_level| 
        access_level.user_id || access_level.access_level 
      end
    }
  end

  def load_gon_index
    params = { open_branches: @project.open_branches.map do |br| 
      { text: br.name, id: br.name, title: br.name } 
    end }
    params.merge!(current_project_id: @project.id) if @project
    gon.push(params.merge(access_levels_options))
  end
end
