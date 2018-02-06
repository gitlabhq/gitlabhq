module Gitlab
  module Ci
    module Build
      module Artifacts
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
            attr_reader :entries
            attr_accessor :name

            def initialize(path, entries)
              @entries = entries
              @path = Artifacts::Path.new(path)
            end

            delegate :empty?, to: :children

            def directory?
              blank_node? || @path.directory?
            end

            def file?
              !directory?
            end

            def blob
              return unless file?

              @blob ||= Blob.decorate(::Ci::ArtifactBlob.new(self), nil)
            end

            def has_parent?
              nodes > 0
            end

            def parent
              return nil unless has_parent?

              self.class.new(@path.to_s.chomp(basename), @entries)
            end

            def basename
              (directory? && !blank_node?) ? name + '/' : name
            end

            def name
              @name || @path.name
            end

            def children
              return [] unless directory?
              return @children if @children

              child_pattern = %r{^#{Regexp.escape(@path.to_s)}[^/]+/?$}
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
              @entries[@path.to_s] || {}
            end

            def nodes
              @path.nodes + (file? ? 1 : 0)
            end

            def blank_node?
              @path.to_s.empty? # "" is considered to be './'
            end

            def exists?
              blank_node? || @entries.include?(@path.to_s)
            end

            def total_size
              descendant_pattern = /^#{Regexp.escape(@path.to_s)}/
              entries.sum do |path, entry|
                (entry[:size] if path =~ descendant_pattern).to_i
              end
            end

            def path
              @path.to_s
            end

            def to_s
              @path.to_s
            end

            def ==(other)
              path == other.path && @entries == other.entries
            end

            def inspect
              "#{self.class.name}: #{self}"
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
  end
end
