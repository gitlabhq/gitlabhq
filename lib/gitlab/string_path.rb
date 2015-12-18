module Gitlab
  ## 
  # Class that represents a path to a file or directory
  #
  # This is IO-operations safe class, that does similar job to 
  # Ruby's Pathname but without the risk of accessing filesystem.
  #
  #
  class StringPath
    def initialize(path, universe)
      @path = path
      @universe = universe
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

    def to_s
      @path
    end
  end
end
