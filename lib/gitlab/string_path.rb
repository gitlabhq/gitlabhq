module Gitlab
  ## 
  # Class that represents a path to a file or directory
  #
  # This is IO-operations safe class, that does similar job to 
  # Ruby's Pathname but without the risk of accessing filesystem.
  #
  #
  class StringPath
    attr_reader :path, :universe

    def initialize(path, universe)
      @path = path
      @universe = universe
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

    def directories
      raise NotImplementedError
    end

    def files
      raise NotImplementedError
    end

    def basename
      name = @path.split(::File::SEPARATOR).last
      directory? ? name + ::File::SEPARATOR : name
    end

    def ==(other)
      @path == other.path && @universe == other.universe
    end

    private

    def new(path)
      self.class.new(path, @universe)
    end
  end
end
