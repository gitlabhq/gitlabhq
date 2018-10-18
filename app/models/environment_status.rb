# frozen_string_literal: true

class EnvironmentStatus
  include Gitlab::Utils::StrongMemoize

  attr_reader :environment, :merge_request

  delegate :id, to: :environment
  delegate :name, to: :environment
  delegate :project, to: :environment
  delegate :deployed_at, to: :deployment, allow_nil: true

  def initialize(environment, merge_request)
    @environment = environment
    @merge_request = merge_request
  end

  def deployment
    strong_memoize(:deployment) do
      environment.first_deployment_for(merge_request.diff_head_sha)
    end
  end

  def deployed_at
    deployment&.created_at
  end

  def changes
    sha = merge_request.diff_head_sha
    return [] if project.route_map_for(sha).nil?

    changed_files.map { |file| build_change(file, sha) }.compact
  end

  def changed_files
    merge_request.merge_request_diff
      .merge_request_diff_files.where(deleted_file: false)
  end

  private

  PAGE_EXTENSIONS = /\A\.(s?html?|php|asp|cgi|pl)\z/i.freeze

  def build_change(file, sha)
    public_path = project.public_path_for_source_path(file.new_path, sha)
    return if public_path.nil?

    ext = File.extname(public_path)
    return if ext.present? && ext !~ PAGE_EXTENSIONS

    {
      path: public_path,
      external_url: environment.external_url_for(file.new_path, sha)
    }
  end
end
