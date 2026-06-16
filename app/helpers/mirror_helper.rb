# frozen_string_literal: true

module MirrorHelper
  PUSH_DIRECTION = 'push'
  PULL_DIRECTION = 'pull'

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

  def remote_mirrors_table_data(remote_mirrors)
    Gitlab::Json.dump(remote_mirrors.map { |m| serialize_remote_mirror_row(m) })
  end

  private

  # Shared builder for both push and pull mirror JSON rows.
  # Both directions use this to ensure the Vue table contract
  # has a single source of truth.
  #
  # Note: last_update_at represents "last successful update" for
  # both push and pull mirrors. For push mirrors the caller
  # passes RemoteMirror#last_update_at (set only on success).
  # For pull mirrors the caller passes
  # ImportState#last_successful_update_at.
  # rubocop:disable Metrics/ParameterLists -- all keyword args are required to enforce the Vue table contract
  def serialize_mirror_row(
    id:, enabled:, url:, direction:, last_update_started_at:, last_update_at:, last_error:,
    update_status:, ssh_key_auth:, ssh_public_key:, archived: nil)
    # rubocop:enable Metrics/ParameterLists
    {
      id: id,
      enabled: enabled,
      url: url,
      direction: direction,
      last_update_started_at: last_update_started_at&.iso8601,
      last_update_at: last_update_at&.iso8601,
      last_error: last_error&.strip,
      update_status: update_status,
      ssh_key_auth: ssh_key_auth,
      ssh_public_key: ssh_public_key,
      archived: archived
    }
  end

  # Use read_attribute(:enabled) to get the raw DB column value,
  # bypassing RemoteMirror#enabled which applies project-level
  # checks (remote_mirror_available?, repository_exists?, etc.).
  # The Vue table needs the per-mirror toggle state, not the
  # computed project-aware value.
  def serialize_remote_mirror_row(mirror)
    serialize_mirror_row(
      id: mirror.id,
      enabled: mirror.read_attribute(:enabled),
      url: mirror.safe_url,
      direction: PUSH_DIRECTION,
      last_update_started_at: mirror.last_update_started_at,
      last_update_at: mirror.last_update_at,
      last_error: mirror.last_error,
      update_status: mirror.update_status,
      ssh_key_auth: mirror.ssh_key_auth?,
      ssh_public_key: mirror.ssh_public_key
    )
  end
end

MirrorHelper.prepend_mod_with('MirrorHelper')
