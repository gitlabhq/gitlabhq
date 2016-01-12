module Gitlab
  module Ci::Build::Artifacts
    class Metadata
      ##
      # Class that represents a simplified path to a file or
      # directory in GitLab CI Build Artifacts binary file / archive
      #
      # This is IO-operations safe class, that does similar job to
      # Ruby's Pathname but without the risk of accessing filesystem.
      #
      # This class is working only with UTF-8 encoded paths.
      #
      class Path
        attr_reader :path, :universe
        attr_accessor :name

        def initialize(path, universe, metadata = [])
          @path = path.force_encoding('UTF-8')
          @universe = universe
          @metadata = metadata

          if path.include?("\0")
            raise ArgumentError, 'Path contains zero byte character!'
          end

          unless path.valid_encoding?
            raise ArgumentError, 'Path contains non-UTF-8 byte sequence!'
          end
        end

        def directory?
          blank_node? || @path.end_with?('/')
        end

        def file?
          !directory?
        end

        def has_parent?
          nodes > 0
        end

        def parent
          return nil unless has_parent?
          new(@path.chomp(basename))
        end

        def basename
          (directory? && !blank_node?) ? name + ::File::SEPARATOR : name
        end

        def name
          @name || @path.split(::File::SEPARATOR).last.to_s
        end

        def children
          return [] unless directory?
          return @children if @children

          child_pattern = %r{^#{Regexp.escape(@path)}[^/]+/?$}
          @children = select { |entry| entry =~ child_pattern }
        end

        def directories
          return [] unless directory?
          children.select(&:directory?)
        end

        def directories!
          return directories unless has_parent?

          dotted_parent = parent
          dotted_parent.name = '..'
          directories.prepend(dotted_parent)
        end

        def files
          return [] unless directory?
          children.select(&:file?)
        end

        def metadata
          @index ||= @universe.index(@path)
          @metadata[@index] || {}
        end

        def nodes
          @path.count('/') + (file? ? 1 : 0)
        end

        def exists?
          blank_node? || @universe.include?(@path)
        end

        def blank_node?
          @path.empty? # "" is considered to be './'
        end

        def to_s
          @path
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
      end
    end
  end
end
