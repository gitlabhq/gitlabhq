module ContainerRegistry
  class Path
    InvalidRegistryPathError = Class.new(StandardError)

    def initialize(name)
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

    def repository_project
      @project ||= Project.where_full_path_in(components.first(3))&.first
    end

    def repository_name
    end
  end
end
