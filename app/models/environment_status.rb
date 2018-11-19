# frozen_string_literal: true

class EnvironmentStatus
  include Gitlab::Utils::StrongMemoize

  attr_reader :environment, :merge_request, :sha

  delegate :id, to: :environment
  delegate :name, to: :environment
  delegate :project, to: :environment
  delegate :deployed_at, to: :deployment, allow_nil: true

  def self.for_merge_request(mr, user)
    build_environments_status(mr, user, mr.diff_head_sha)
  end

  def self.after_merge_request(mr, user)
    return [] unless mr.merged?

    build_environments_status(mr, user, mr.merge_commit_sha)
  end

  def initialize(environment, merge_request, sha)
    @environment = environment
    @merge_request = merge_request
    @sha = sha
  end

  def deployment
    strong_memoize(:deployment) do
      Deployment.where(environment: environment).find_by_sha(sha)
    end
  end

  def changes
    return [] if project.route_map_for(sha).nil?

    changed_files.map { |file| build_change(file) }.compact
  end

  def changed_files
    merge_request.merge_request_diff
      .merge_request_diff_files.where(deleted_file: false)
  end

  ##
  # Since frontend has not supported all statuses yet, BE has to
  # proxy some status to a supported status.
  def status
    return unless deployment

    case deployment.status
    when 'created'
      'running'
    when 'canceled'
      'failed'
    else
      deployment.status
    end
  end

  private

  PAGE_EXTENSIONS = /\A\.(s?html?|php|asp|cgi|pl)\z/i.freeze

  def build_change(file)
    public_path = project.public_path_for_source_path(file.new_path, sha)
    return if public_path.nil?

    ext = File.extname(public_path)
    return if ext.present? && ext !~ PAGE_EXTENSIONS

    {
      path: public_path,
      external_url: environment.external_url_for(file.new_path, sha)
    }
  end

  def self.build_environments_status(mr, user, sha)
    Environment.where(project_id: [mr.source_project_id, mr.target_project_id])
               .available
               .with_deployment(sha).map do |environment|
      next unless Ability.allowed?(user, :read_environment, environment)

      EnvironmentStatus.new(environment, mr, sha)
    end.compact
  end
  private_class_method :build_environments_status
end
