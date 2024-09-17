# frozen_string_literal: true

module ContainerRegistry
  ##
  # Class responsible for extracting project and repository name from
  # image repository path provided by a containers registry API response.
  #
  # Example:
  #
  # some/group/my_project/my/image ->
  #   project: some/group/my_project
  #   repository: my/image
  #
  class Path
    InvalidRegistryPathError = Class.new(StandardError)

    LEVELS_SUPPORTED = 3

    attr_reader :project

    # The 'project' argument is optional.
    # If provided during initialization, it will limit the path to the specified project,
    # potentially reducing the need for a database query.
    def initialize(path, project: nil)
      @path = path.to_s.downcase
      @project = project
    end

    def valid?
      @path =~ Gitlab::Regex.container_repository_name_regex &&
        components.size > 1 &&
        components.size < Namespace::NUMBER_OF_ANCESTORS_ALLOWED
    end

    def components
      @components ||= @path.split('/')
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def nodes
      raise InvalidRegistryPathError unless valid?

      @nodes ||= components.size.downto(2).map do |length|
        components.take(length).join('/')
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def has_project?
      repository_project.present?
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def has_repository?
      return false unless has_project?

      repository_project.container_repositories
        .where(name: repository_name).any?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def root_repository?
      @path == project_path
    end

    def repository_project
      @project ||= Project
        .where_full_path_in(nodes.first(LEVELS_SUPPORTED))
        .first
    end

    def repository_name
      return unless has_project?

      @path.remove(%r{^#{Regexp.escape(project_path)}/?})
    end

    def project_path
      return unless has_project?

      repository_project.full_path.downcase
    end

    def to_s
      @path
    end
  end
end
