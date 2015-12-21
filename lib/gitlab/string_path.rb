module Gitlab
  ## 
  # Class that represents a simplified path to a file or directory
  #
  # This is IO-operations safe class, that does similar job to 
  # Ruby's Pathname but without the risk of accessing filesystem.
  #
  #
  class StringPath
    attr_reader :path, :universe

    def initialize(path, universe)
      @path = prepare(path)
      @universe = universe.map { |entry| prepare(entry) }
      @universe.unshift('./') unless @universe.include?('./')
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
      name = @path.split(::File::SEPARATOR).last
      directory? ? name + ::File::SEPARATOR : name
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
      descendants.select { |descendant| descendant.parent == self }
    end

    def directories
      return [] unless directory?
      children.select { |child| child.directory? }
    end

    def files
      return [] unless directory?
      children.select { |child| child.file? }
    end

    def ==(other)
      @path == other.path && @universe == other.universe
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
