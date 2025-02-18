# frozen_string_literal: true

module MirrorHelper
  def mirrors_form_data_attributes
    {
      project_mirror_ssh_endpoint: ssh_host_keys_project_mirror_path(@project, :json),
      project_mirror_endpoint: project_mirror_path(@project, :json)
    }
  end

  def pull_mirror_lfs_sync_message
    template = _(
      'Pull mirrors will only create LFS objects if LFS is %{docs_link_start}enabled ' \
        'for the project%{docs_link_end}.'
    )

    docs_link = link_to('', help_page_path('topics/git/lfs/_index.md'), target: '_blank', rel: 'noopener noreferrer')

    safe_format(template, tag_pair(docs_link, :docs_link_start, :docs_link_end))
  end

  def push_mirror_lfs_sync_message
    template = _(
      'Push mirrors will only sync LFS objects if LFS is %{docs_link_start}enabled ' \
        'for the project%{docs_link_end}.'
    )

    docs_link = link_to('', help_page_path('topics/git/lfs/_index.md'), target: '_blank', rel: 'noopener noreferrer')

    safe_format(template, tag_pair(docs_link, :docs_link_start, :docs_link_end))
  end

  def push_mirror_lfs_ssh_sync_message
    template = _('Push mirrors will %{strong_open}not%{strong_close} sync LFS objects over SSH.')

    safe_format(template, tag_pair(tag.strong, :strong_open, :strong_close))
  end

  def mirrored_repositories_count
    count = @project.mirror == true ? 1 : 0
    count + @project.remote_mirrors.to_a.count(&:enabled)
  end
end

MirrorHelper.prepend_mod_with('MirrorHelper')
