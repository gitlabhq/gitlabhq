# frozen_string_literal: true

class EnvironmentStatus
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
    @deployment ||= environment.first_deployment_for(merge_request.diff_head_sha)
  end

  def deployed_at
    deployment.try(:created_at)
  end

  PAGE_EXTENSIONS = /(^$|^\.(s?html?|php|asp|cgi|pl)$)/i.freeze

  def changes
    sha = merge_request.diff_head_sha
    return [] if project.route_map_for(sha).nil?

    merge_request.merge_request_diff.merge_request_diff_files.where(deleted_file: false).map do |file|
      public_path = project.public_path_for_source_path(file.new_path, sha)
      next if public_path.nil?

      next unless File.extname(public_path) =~ PAGE_EXTENSIONS

      {
        path: public_path,
        external_url: environment.external_url_for(file.new_path, sha)
      }
    end.compact
  end
end
