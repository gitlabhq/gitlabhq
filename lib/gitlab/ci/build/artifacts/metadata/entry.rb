module Gitlab
  module Ci::Build::Artifacts
    class Metadata
      ##
      # Class that represents an entry (path and metadata) to a file or
      # directory in GitLab CI Build Artifacts binary file / archive
      #
      # This is IO-operations safe class, that does similar job to
      # Ruby's Pathname but without the risk of accessing filesystem.
      #
      # This class is working only with UTF-8 encoded paths.
      #
      class Entry
        attr_reader :path, :entries
        attr_accessor :name

        def initialize(path, entries)
          @path = path.dup.force_encoding('UTF-8')
          @entries = entries

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
          self.class.new(@path.chomp(basename), @entries)
        end

        def basename
          (directory? && !blank_node?) ? name + '/' : name
        end

        def name
          @name || @path.split('/').last.to_s
        end

        def children
          return [] unless directory?
          return @children if @children

          child_pattern = %r{^#{Regexp.escape(@path)}[^/]+/?$}
          @children = select_entries { |path| path =~ child_pattern }
        end

        def directories(opts = {})
          return [] unless directory?
          dirs = children.select(&:directory?)
          return dirs unless has_parent? && opts[:parent]

          dotted_parent = parent
          dotted_parent.name = '..'
          dirs.prepend(dotted_parent)
        end

        def files
          return [] unless directory?
          children.select(&:file?)
        end

        def metadata
          @entries[@path] || {}
        end

        def nodes
          @path.count('/') + (file? ? 1 : 0)
        end

        def blank_node?
          @path.empty? # "" is considered to be './'
        end

        def exists?
          blank_node? || @entries.include?(@path)
        end

        def empty?
          children.empty?
        end

        def total_size
          descendant_pattern = %r{^#{Regexp.escape(@path)}}
          entries.sum do |path, entry|
            (entry[:size] if path =~ descendant_pattern).to_i
          end
        end

        def to_s
          @path
        end

        def ==(other)
          @path == other.path && @entries == other.entries
        end

        def inspect
          "#{self.class.name}: #{@path}"
        end

        private

        def select_entries
          selected = @entries.select { |path, _metadata| yield path }
          selected.map { |path, _metadata| self.class.new(path, @entries) }
        end
      end
    end
  end
end
