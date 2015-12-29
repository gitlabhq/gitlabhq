module Gitlab
  ## 
  # Class that represents a simplified path to a file or directory
  #
  # This is IO-operations safe class, that does similar job to 
  # Ruby's Pathname but without the risk of accessing filesystem.
  #
  # TODO: better support for '../' and './'
  #
  class StringPath
    attr_reader :path, :universe

    def initialize(path, universe)
      @path = prepare(path)
      @universe = Set.new(universe.map { |entry| prepare(entry) })
      @universe.add('./')
    end

    def to_s
      @path
    end

    def absolute?
      @path.start_with?('/')
    end

    def relative?
      !absolute?
    end

    def directory?
      @path.end_with?('/')
    end

    def file?
      !directory?
    end

    def has_parent?
      @universe.include?(@path.sub(basename, ''))
    end

    def parent
      return nil unless has_parent?
      new(@path.sub(basename, ''))
    end

    def basename
      directory? ? name + ::File::SEPARATOR : name
    end

    def name
      @path.split(::File::SEPARATOR).last
    end

    def has_descendants?
      descendants.any?
    end

    def descendants
      return [] unless directory?
      children = @universe.select { |entry| entry =~ /^#{@path}.+/ }
      children.map { |path| new(path) }
    end

    def children
      return [] unless directory?
      return @children if @children
      children = @universe.select { |entry| entry =~ %r{^#{@path}[^/]+/?$} }
      @children = children.map { |path| new(path) }
    end

    def directories
      return [] unless directory?
      children.select(&:directory?)
    end

    def directories!
      has_parent? ? directories.prepend(new(@path + '../')) : directories
    end

    def files
      return [] unless directory?
      children.select(&:file?)
    end

    def ==(other)
      @path == other.path && @universe == other.universe
    end

    def inspect
      "#{self.class.name}: #{@path}"
    end

    private

    def new(path)
      self.class.new(path, @universe)
    end

    def prepare(path)
      return path if path =~ %r{^(/|\.|\.\.)}
      path.dup.prepend('./')
    end
  end
end
