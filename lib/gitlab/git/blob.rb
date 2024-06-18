# frozen_string_literal: true

module Gitlab
  module Git
    class Blob
      include Gitlab::BlobHelper
      include Gitlab::EncodingHelper
      extend Gitlab::Git::WrapsGitalyErrors

      # This number is the maximum amount of data that we want to display to
      # the user. We load as much as we can for encoding detection and LFS
      # pointer parsing. All other cases where we need full blob data should
      # use load_all_data!.
      MAX_DATA_DISPLAY_SIZE = 10.megabytes

      # The number of blobs loaded in a single Gitaly call
      # When a large number of blobs requested, we'd want to fetch them in
      # multiple Gitaly calls
      BATCH_SIZE = 250

      # These limits are used as a heuristic to ignore files which can't be LFS
      # pointers. The format of these is described in
      # https://github.com/git-lfs/git-lfs/blob/master/docs/spec.md#the-pointer
      LFS_POINTER_MIN_SIZE = 120.bytes
      LFS_POINTER_MAX_SIZE = 200.bytes

      attr_accessor :size, :mode, :id, :commit_id, :loaded_size, :binary
      attr_writer :name, :path, :data
      attr_reader :raw

      def self.gitlab_blob_truncated_true
        @gitlab_blob_truncated_true ||= ::Gitlab::Metrics.counter(:gitlab_blob_truncated_true, 'blob.truncated? == true')
      end

      def self.gitlab_blob_truncated_false
        @gitlab_blob_truncated_false ||= ::Gitlab::Metrics.counter(:gitlab_blob_truncated_false, 'blob.truncated? == false')
      end

      def self.gitlab_blob_size
        @gitlab_blob_size ||= ::Gitlab::Metrics.histogram(
          :gitlab_blob_size,
          'Gitlab::Git::Blob size',
          {},
          [1_000, 5_000, 10_000, 50_000, 100_000, 500_000, 1_000_000]
        )
      end

      class << self
        def find(repository, sha, path, limit: MAX_DATA_DISPLAY_SIZE)
          tree_entry(repository, sha, path, limit)
        end

        def tree_entry(repository, sha, path, limit)
          return unless path

          path = path.sub(%r{\A/*}, '')
          path = '/' if path.empty?
          name = File.basename(path)

          # Gitaly will think that setting the limit to 0 means unlimited, while
          # the client might only need the metadata and thus set the limit to 0.
          # In this method we'll then set the limit to 1, but clear the byte of data
          # that we got back so for the outside world it looks like the limit was
          # actually 0.
          req_limit = limit == 0 ? 1 : limit

          entry = Gitlab::GitalyClient::CommitService.new(repository).tree_entry(sha, path, req_limit)
          return unless entry

          entry.data = "" if limit == 0

          case entry.type
          when :COMMIT
            new(id: entry.oid, name: name, size: 0, data: '', path: path, commit_id: sha)
          when :BLOB
            new(id: entry.oid, name: name, size: entry.size, data: entry.data.dup, mode: entry.mode.to_s(8),
              path: path, commit_id: sha, binary: binary?(entry.data))
          end
        end

        def raw(repository, sha, limit: MAX_DATA_DISPLAY_SIZE)
          repository.gitaly_blob_client.get_blob(oid: sha, limit: limit)
        end

        # Returns an array of Blob instances, specified in blob_references as
        # [[commit_sha, path], [commit_sha, path], ...]. If blob_size_limit < 0 then the
        # full blob contents are returned. If blob_size_limit >= 0 then each blob will
        # contain no more than limit bytes in its data attribute.
        #
        # Keep in mind that this method may allocate a lot of memory. It is up
        # to the caller to limit the number of blobs and blob_size_limit.
        #
        def batch(repository, blob_references, blob_size_limit: MAX_DATA_DISPLAY_SIZE)
          blob_references.each_slice(BATCH_SIZE).flat_map do |refs|
            repository.gitaly_blob_client.get_blobs(refs, blob_size_limit).to_a
          end
        end

        # Returns an array of Blob instances just with the metadata, that means
        # the data attribute has no content.
        def batch_metadata(repository, blob_references)
          batch(repository, blob_references, blob_size_limit: 0)
        end

        # Find LFS blobs given an array of sha ids
        # Returns array of Gitlab::Git::Blob
        # Does not guarantee blob data will be set
        def batch_lfs_pointers(repository, blob_ids)
          wrapped_gitaly_errors do
            repository.gitaly_blob_client.batch_lfs_pointers(blob_ids.to_a)
          end
        end

        def binary?(data)
          EncodingHelper.detect_libgit2_binary?(data)
        end

        def size_could_be_lfs?(size)
          size.between?(LFS_POINTER_MIN_SIZE, LFS_POINTER_MAX_SIZE)
        end
      end

      def initialize(options)
        %w[id name path size data mode commit_id binary].each do |key|
          self.__send__("#{key}=", options[key.to_sym]) # rubocop:disable GitlabSecurity/PublicSend
        end

        # Retain the actual size before it is encoded
        @loaded_size = @data.bytesize if @data
        @loaded_all_data = @loaded_size == size

        # Retain the data before it is encoded
        @raw = @data.dup

        # Recalculate binary status if we loaded all data
        @binary = nil if @loaded_all_data

        record_metric_blob_size
        record_metric_truncated(truncated?)
      end

      def binary_in_repo?
        @binary.nil? ? super : @binary == true
      end

      def data
        encode! @data
      end

      # Load all blob data (not just the first MAX_DATA_DISPLAY_SIZE bytes) into
      # memory as a Ruby string.
      def load_all_data!(repository)
        return if @data == '' # don't mess with submodule blobs

        # Even if we return early, recalculate whether this blob is binary in
        # case a blob was initialized as text but the full data isn't
        @binary = nil

        return if @loaded_all_data

        @data = repository.gitaly_blob_client.get_blob(oid: id, limit: -1).data
        @loaded_all_data = true
        @loaded_size = @data.bytesize
      end

      def name
        encode! @name
      end

      def path
        encode! @path
      end

      def truncated?
        return false unless size && loaded_size

        size > loaded_size
      end

      # Valid LFS object pointer is a text file consisting of
      # version
      # oid
      # size
      # see https://github.com/github/git-lfs/blob/v1.1.0/docs/spec.md#the-pointer
      def lfs_pointer?
        self.class.size_could_be_lfs?(size) && has_lfs_version_key? && lfs_oid.present? && lfs_size.present?
      end

      def lfs_oid
        if has_lfs_version_key?
          oid = data.match(/(?<=sha256:)([0-9a-f]{64})/)
          return oid[1] if oid
        end

        nil
      end

      def lfs_size
        if has_lfs_version_key?
          size = data.match(/(?<=size )([0-9]+)/)
          return size[1].to_i if size
        end

        nil
      end

      def external_storage
        return unless lfs_pointer?

        :lfs
      end

      alias_method :external_size, :lfs_size

      private

      def record_metric_blob_size
        return unless size

        self.class.gitlab_blob_size.observe({}, size)
      end

      def record_metric_truncated(bool)
        if bool
          self.class.gitlab_blob_truncated_true.increment
        else
          self.class.gitlab_blob_truncated_false.increment
        end
      end

      def has_lfs_version_key?
        !empty? && text_in_repo? && data.start_with?("version https://git-lfs.github.com/spec")
      end
    end
  end
end
