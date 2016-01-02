module Gitlab
  ## 
  # Class that represents a simplified path to a file or directory
  #
  # This is IO-operations safe class, that does similar job to 
  # Ruby's Pathname but without the risk of accessing filesystem.
  #
  class StringPath
    attr_reader :path, :universe

    def initialize(path, universe, metadata = [])
      @path = sanitize(path)
      @universe = universe.map { |entry| sanitize(entry) }
      @metadata = metadata
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
      select { |entry| entry =~ /^#{@path}.+/ }
    end

    def children
      return [] unless directory?
      return @children if @children

      @children = select do |entry|
        self.class.child?(@path, entry)
      end
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

    def metadata
      index = @universe.index(@path)
      @metadata[index]
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

    def select
      selected = @universe.select { |entry| yield entry }
      selected.map { |path| new(path) }
    end

    def sanitize(path)
      self.class.sanitize(path)
    end

    def self.sanitize(path)
      # It looks like Pathname#new doesn't touch a file system,
      # neither Pathname#cleanpath does, so it is, hopefully, filesystem safe

      clean = Pathname.new(path).cleanpath.to_s
      raise ArgumentError, 'Invalid path' if clean.start_with?('../')
      clean + (path.end_with?('/') ? '/' : '')
    end

    def self.child?(path, entry)
      entry =~ %r{^#{path}[^/\s]+/?$}
    end
  end
end
