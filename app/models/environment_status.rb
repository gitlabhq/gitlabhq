# frozen_string_literal: true

class EnvironmentStatus
  include Gitlab::Utils::StrongMemoize

  attr_reader :environment, :merge_request, :sha

  delegate :id, to: :environment
  delegate :name, to: :environment
  delegate :project, to: :environment
  delegate :status, to: :deployment, allow_nil: true
  delegate :deployed_at, to: :deployment, allow_nil: true

  def self.for_merge_request(mr, user)
    build_environments_status(mr, user, mr.head_pipeline)
  end

  def self.after_merge_request(mr, user)
    return [] unless mr.merged?

    build_environments_status(mr, user, mr.merge_pipeline)
  end

  def initialize(environment, merge_request, sha)
    @environment = environment
    @merge_request = merge_request
    @sha = sha
  end

  def deployment
    strong_memoize(:deployment) do
      environment.first_deployment_for(sha)
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

  def self.build_environments_status(mr, user, pipeline)
    return [] unless pipeline.present?

    find_environments(user, pipeline).map do |environment|
      EnvironmentStatus.new(environment, mr, pipeline.sha)
    end
  end
  private_class_method :build_environments_status

  def self.find_environments(user, pipeline)
    env_ids = Deployment.where(deployable: pipeline.builds).select(:environment_id)

    Environment.available.where(id: env_ids).select do |environment|
      Ability.allowed?(user, :read_environment, environment)
    end
  end
  private_class_method :find_environments
end
