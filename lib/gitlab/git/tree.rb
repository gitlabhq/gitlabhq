module Gitlab
  module Git
    class Tree
      include Linguist::BlobHelper

      attr_accessor :repository, :sha, :path, :ref, :raw_tree

      def initialize(repository, sha, ref = nil, path = nil)
        @repository, @sha, @ref = repository, sha, ref

        # Load tree from repository
        @commit = @repository.commit(sha)
        @raw_tree = @repository.tree(@commit, path)
      end

      def empty?
        data.blank?
      end

      def data
        raw_tree.data
      end

      def is_blob?
        tree.is_a?(Grit::Blob)
      end

      def up_dir?
        path.present?
      end

      def readme
        @readme ||= contents.find { |c| c.is_a?(Grit::Blob) and c.name =~ /^readme/i }
      end
    end
  end
end

