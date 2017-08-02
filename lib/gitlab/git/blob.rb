# Gitaly note: JV: seems to be completely migrated (behind feature flags).

module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper
      include Gitlab::EncodingHelper

      # This number is the maximum amount of data that we want to display to
      # the user. We load as much as we can for encoding detection
      # (Linguist) and LFS pointer parsing. All other cases where we need full
      # blob data should use load_all_data!.
      MAX_DATA_DISPLAY_SIZE = 10.megabytes

      attr_accessor :name, :path, :size, :data, :mode, :id, :commit_id, :loaded_size, :binary

      class << self
        def find(repository, sha, path)
          Gitlab::GitalyClient.migrate(:project_raw_show) do |is_enabled|
            if is_enabled
              find_by_gitaly(repository, sha, path)
            else
              find_by_rugged(repository, sha, path)
            end
          end
        end

        def find_by_gitaly(repository, sha, path)
          path = path.sub(/\A\/*/, '')
          path = '/' if path.empty?
          name = File.basename(path)
          entry = Gitlab::GitalyClient::CommitService.new(repository).tree_entry(sha, path, MAX_DATA_DISPLAY_SIZE)
          return unless entry

          case entry.type
          when :COMMIT
            new(
              id: entry.oid,
              name: name,
              size: 0,
              data: '',
              path: path,
              commit_id: sha
            )
          when :BLOB
            new(
              id: entry.oid,
              name: name,
              size: entry.size,
              data: entry.data.dup,
              mode: entry.mode.to_s(8),
              path: path,
              commit_id: sha,
              binary: binary?(entry.data)
            )
          end
        end

        def find_by_rugged(repository, sha, path)
          commit = repository.lookup(sha)
          root_tree = commit.tree

          blob_entry = find_entry_by_path(repository, root_tree.oid, path)

          return nil unless blob_entry

          if blob_entry[:type] == :commit
            submodule_blob(blob_entry, path, sha)
          else
            blob = repository.lookup(blob_entry[:oid])

            if blob
              new(
                id: blob.oid,
                name: blob_entry[:name],
                size: blob.size,
                data: blob.content(MAX_DATA_DISPLAY_SIZE),
                mode: blob_entry[:filemode].to_s(8),
                path: path,
                commit_id: sha,
                binary: blob.binary?
              )
            end
          end
        end

        def raw(repository, sha)
          Gitlab::GitalyClient.migrate(:git_blob_raw) do |is_enabled|
            if is_enabled
              Gitlab::GitalyClient::BlobService.new(repository).get_blob(oid: sha, limit: MAX_DATA_DISPLAY_SIZE)
            else
              blob = repository.lookup(sha)

              new(
                id: blob.oid,
                size: blob.size,
                data: blob.content(MAX_DATA_DISPLAY_SIZE),
                binary: blob.binary?
              )
            end
          end
        end

        def binary?(data)
          # EncodingDetector checks the first 1024 * 1024 bytes for NUL byte, libgit2 checks
          # only the first 8000 (https://github.com/libgit2/libgit2/blob/2ed855a9e8f9af211e7274021c2264e600c0f86b/src/filter.h#L15),
          # which is what we use below to keep a consistent behavior.
          detect = CharlockHolmes::EncodingDetector.new(8000).detect(data)
          detect && detect[:type] == :binary
        end

        private

        # Recursive search of blob id by path
        #
        # Ex.
        #   blog/            # oid: 1a
        #     app/           # oid: 2a
        #       models/      # oid: 3a
        #       file.rb      # oid: 4a
        #
        #
        # Blob.find_entry_by_path(repo, '1a', 'app/file.rb') # => '4a'
        #
        def find_entry_by_path(repository, root_id, path)
          root_tree = repository.lookup(root_id)
          # Strip leading slashes
          path[/^\/*/] = ''
          path_arr = path.split('/')

          entry = root_tree.find do |entry|
            entry[:name] == path_arr[0]
          end

          return nil unless entry

          if path_arr.size > 1
            return nil unless entry[:type] == :tree
            path_arr.shift
            find_entry_by_path(repository, entry[:oid], path_arr.join('/'))
          else
            [:blob, :commit].include?(entry[:type]) ? entry : nil
          end
        end

        def submodule_blob(blob_entry, path, sha)
          new(
            id: blob_entry[:oid],
            name: blob_entry[:name],
            size: 0,
            data: '',
            path: path,
            commit_id: sha
          )
        end
      end

      def initialize(options)
        %w(id name path size data mode commit_id binary).each do |key|
          self.send("#{key}=", options[key.to_sym])
        end

        @loaded_all_data = false
        # Retain the actual size before it is encoded
        @loaded_size = @data.bytesize if @data
      end

      def binary?
        @binary.nil? ? super : @binary == true
      end

      def data
        encode! @data
      end

      # Load all blob data (not just the first MAX_DATA_DISPLAY_SIZE bytes) into
      # memory as a Ruby string.
      def load_all_data!(repository)
        return if @data == '' # don't mess with submodule blobs
        return @data if @loaded_all_data

        Gitlab::GitalyClient.migrate(:git_blob_load_all_data) do |is_enabled|
          @data = begin
            if is_enabled
              Gitlab::GitalyClient::BlobService.new(repository).get_blob(oid: id, limit: -1).data
            else
              repository.lookup(id).content
            end
          end
        end

        @loaded_all_data = true
        @loaded_size = @data.bytesize
        @binary = nil
      end

      def name
        encode! @name
      end

      def path
        encode! @path
      end

      def truncated?
        size && (size > loaded_size)
      end

      # Valid LFS object pointer is a text file consisting of
      # version
      # oid
      # size
      # see https://github.com/github/git-lfs/blob/v1.1.0/docs/spec.md#the-pointer
      def lfs_pointer?
        has_lfs_version_key? && lfs_oid.present? && lfs_size.present?
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

      def has_lfs_version_key?
        !empty? && text? && data.start_with?("version https://git-lfs.github.com/spec")
      end
    end
  end
end
