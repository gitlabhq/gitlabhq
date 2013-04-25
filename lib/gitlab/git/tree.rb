module Gitlab
  module Git
    class Tree
      attr_accessor :repository, :sha, :path, :ref, :raw_tree, :id

      def initialize(repository, sha, ref = nil, path = nil)
        @repository, @sha, @ref, @path = repository, sha, ref, path

        @path = nil if @path.blank?

        # Load tree from repository
        @commit = @repository.commit(@sha)
        @raw_tree = @repository.tree(@commit, @path)
      end

      def exists?
        raw_tree
      end

      def empty?
        data.blank?
      end

      def trees
        entries.select { |t| t.is_a?(Grit::Tree) }
      end

      def blobs
        entries.select { |t| t.is_a?(Grit::Blob) }
      end

      def is_blob?
        raw_tree.is_a?(Grit::Blob)
      end

      def up_dir?
        path.present?
      end

      def readme
        @readme ||= blobs.find { |c| c.name =~ /^readme/i }
      end

      protected

      def entries
        raw_tree.contents
      end
    end
  end
end

