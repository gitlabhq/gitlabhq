# frozen_string_literal: true

module MirrorHelper
  def mirrors_form_data_attributes
    {
      project_mirror_ssh_endpoint: ssh_host_keys_project_mirror_path(@project, :json),
      project_mirror_endpoint: project_mirror_path(@project, :json)
    }
  end

  def mirror_lfs_sync_message
    docs_link_url = help_page_path('topics/git/lfs/index')
    docs_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: docs_link_url }

    html_escape(_('Git LFS objects will be synced if LFS is %{docs_link_start}enabled for the project%{docs_link_end}. Push mirrors will %{strong_open}not%{strong_close} sync LFS objects over SSH.')) %
        { docs_link_start: docs_link_start, docs_link_end: '</a>'.html_safe, strong_open: '<strong>'.html_safe, strong_close: '</strong>'.html_safe }
  end
end

MirrorHelper.prepend_mod_with('MirrorHelper')
