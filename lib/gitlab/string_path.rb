module Gitlab
  ## 
  # Class that represents a simplified path to a file or directory
  #
  # This is IO-operations safe class, that does similar job to 
  # Ruby's Pathname but without the risk of accessing filesystem.
  #
  class StringPath
    attr_reader :path, :universe
    attr_accessor :name

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
      nodes > 1
    end

    def parent
      return nil unless has_parent?
      new(@path.sub(basename, ''))
    end

    def basename
      directory? ? name + ::File::SEPARATOR : name
    end

    def name
      @name || @path.split(::File::SEPARATOR).last
    end

    def has_descendants?
      descendants.any?
    end

    def descendants
      return [] unless directory?
      select { |entry| entry =~ /^#{Regexp.escape(@path)}.+/ }
    end

    def children
      return [] unless directory?
      return @children if @children

      @children = select do |entry|
        entry =~ %r{^#{Regexp.escape(@path)}[^/\s]+/?$}
      end
    end

    def directories
      return [] unless directory?
      children.select(&:directory?)
    end

    def directories!
      return directories unless has_parent? && directory?

      dotted_parent = parent
      dotted_parent.name = '..'
      directories.prepend(dotted_parent)
    end

    def files
      return [] unless directory?
      children.select(&:file?)
    end

    def metadata
      index = @universe.index(@path)
      @metadata[index] || {}
    end

    def nodes
      @path.count('/') + (file? ? 1 : 0)
    end

    def exists?
      @path == './' || @universe.include?(@path)
    end

    def ==(other)
      @path == other.path && @universe == other.universe
    end

    def inspect
      "#{self.class.name}: #{@path}"
    end

    private

    def new(path)
      self.class.new(path, @universe, @metadata)
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

      clean_path = Pathname.new(path).cleanpath.to_s
      raise ArgumentError, 'Invalid path' if clean_path.start_with?('../')

      prefix = './' unless clean_path =~ %r{^[\.|/]}
      suffix = '/' if path.end_with?('/') || ['.', '..'].include?(clean_path)
      prefix.to_s + clean_path + suffix.to_s
    end
  end
end
