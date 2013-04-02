module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper

      attr_accessor :raw_blob

      delegate :name, to: :raw_blob

      def initialize(repository, sha, ref, path)
        @repository, @sha, @ref = repository, sha, ref

        @commit = @repository.commit(sha)
        @raw_blob = @repository.tree(@commit, path)
      end

      def data
        if raw_blob
          raw_blob.data
        else
          nil
        end
      end

      def exists?
        @raw_blob
      end
    end
  end
end
