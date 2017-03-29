module ContainerRegistry
  ##
  # Class reponsible for extracting project and repository name from
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

    def initialize(path)
      @path = path
      @nodes = path.to_s.split('/')
    end

    def to_s
      @path
    end

    def valid?
      @nodes.size > 1 && @nodes.size < Namespace::NUMBER_OF_ANCESTORS_ALLOWED
    end

    def components
      raise InvalidRegistryPathError unless valid?

      @components ||= @nodes.size.downto(2).map do |length|
        @nodes.take(length).join('/')
      end
    end

    def has_repository?
      # ContainerRepository.find_by_full_path(@path).present?
    end

    def repository_project
      @project ||= Project.where_full_path_in(components.first(3))&.first
    end

    def repository_name
      return unless repository_project

      @path.remove(%r(^?#{Regexp.escape(repository_project.full_path)}/?))
    end
  end
end
