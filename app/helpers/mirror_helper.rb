module MirrorHelper
  def mirrors_form_data_attributes
    { project_mirror_endpoint: project_mirror_path(@project) }
  end
end
