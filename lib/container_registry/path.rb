module ContainerRegistry
  class Path
    InvalidRegistryPathError = Class.new(StandardError)

    def initialize(name)
      @name = name
      @nodes = name.to_s.split('/')
    end

    def valid?
      @nodes.size > 1 &&
      @nodes.size < Namespace::NUMBER_OF_ANCESTORS_ALLOWED
    end

    def components
      raise InvalidRegistryPathError unless valid?

      @components ||= @nodes.size.downto(2).map do |length|
        @nodes.take(length).join('/')
      end
    end

    def has_repository?
      # ContainerRepository.find_by_full_path(@name).present?
    end

    def repository_project
      @project ||= Project.where_full_path_in(components.first(3))&.first
    end

    def repository_name
      return unless repository_project

      @name.remove(%r(^?#{Regexp.escape(repository_project.full_path)}/?))
    end
  end
end
