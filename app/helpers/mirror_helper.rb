# frozen_string_literal: true

module MirrorHelper
  def mirrors_form_data_attributes
    {
      project_mirror_ssh_endpoint: ssh_host_keys_project_mirror_path(@project, :json),
      project_mirror_endpoint: project_mirror_path(@project, :json)
    }
  end

  def mirror_lfs_sync_message
    html_escape(_('The Git LFS objects will %{strong_open}not%{strong_close} be synced.')) % { strong_open: '<strong>'.html_safe, strong_close: '</strong>'.html_safe }
  end
end

MirrorHelper.prepend_if_ee('EE::MirrorHelper')
