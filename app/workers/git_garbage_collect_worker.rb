class GitGarbageCollectWorker
  include Sidekiq::Worker
  include DedicatedSidekiqQueue
  include Gitlab::CurrentSettings

  sidekiq_options retry: false

  def perform(project_id, task = :gc, lease_key = nil, lease_uuid = nil)
    project = Project.find(project_id)
    task = task.to_sym

    cmd = command(task)
    repo_path = project.repository.path_to_repo
    description = "'#{cmd.join(' ')}' in #{repo_path}"

    Gitlab::GitLogger.info(description)

    output, status = Gitlab::Popen.popen(cmd, repo_path)
    Gitlab::GitLogger.error("#{description} failed:\n#{output}") unless status.zero?

    # Refresh the branch cache in case garbage collection caused a ref lookup to fail
    flush_ref_caches(project) if task == :gc
  ensure
    Gitlab::ExclusiveLease.cancel(lease_key, lease_uuid) if lease_key.present? && lease_uuid.present?
  end

  private

  def command(task)
    case task
    when :gc
      git(write_bitmaps: bitmaps_enabled?) + %w[gc]
    when :full_repack
      git(write_bitmaps: bitmaps_enabled?) + %w[repack -A -d --pack-kept-objects]
    when :incremental_repack
      # Normal git repack fails when bitmaps are enabled. It is impossible to
      # create a bitmap here anyway.
      git(write_bitmaps: false) + %w[repack -d]
    else
      raise "Invalid gc task: #{task.inspect}"
    end
  end

  def flush_ref_caches(project)
    project.repository.after_create_branch
    project.repository.branch_names
    project.repository.has_visible_content?
  end

  def bitmaps_enabled?
    current_application_settings.housekeeping_bitmaps_enabled
  end

  def git(write_bitmaps:)
    config_value = write_bitmaps ? 'true' : 'false'
    %W[git -c repack.writeBitmaps=#{config_value}]
  end
end
