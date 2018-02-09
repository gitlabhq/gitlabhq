# Gitaly note: JV: will probably be migrated indirectly by migrating the call sites.

module Gitlab
  module Git
    class RevList
      include Gitlab::Git::Popen

      attr_reader :oldrev, :newrev, :repository

      def initialize(repository, newrev:, oldrev: nil)
        @oldrev = oldrev
        @newrev = newrev
        @repository = repository
      end

      # This method returns an array of new commit references
      def new_refs
        repository.rev_list(including: newrev, excluding: :all).split("\n")
      end

      # Finds newly added objects
      # Returns an array of shas
      #
      # Can skip objects which do not have a path using required_path: true
      # This skips commit objects and root trees, which might not be needed when
      # looking for blobs
      #
      # When given a block it will yield objects as a lazy enumerator so
      # the caller can limit work done instead of processing megabytes of data
      def new_objects(require_path: nil, not_in: nil, &lazy_block)
        opts = {
          including: newrev,
          excluding: not_in.nil? ? :all : not_in,
          require_path: require_path
        }

        get_objects(opts, &lazy_block)
      end

      def all_objects(require_path: nil, &lazy_block)
        get_objects(including: :all, require_path: require_path, &lazy_block)
      end

      # This methods returns an array of missed references
      #
      # Should become obsolete after https://gitlab.com/gitlab-org/gitaly/issues/348.
      def missed_ref
        repository.missed_ref(oldrev, newrev).split("\n")
      end

      private

      def execute(args)
        repository.rev_list(args).split("\n")
      end

      def get_objects(including: [], excluding: [], require_path: nil)
        opts = { including: including, excluding: excluding, objects: true }

        repository.rev_list(opts) do |lazy_output|
          objects = objects_from_output(lazy_output, require_path: require_path)

          yield(objects)
        end
      end

      def objects_from_output(object_output, require_path: nil)
        object_output.map do |output_line|
          sha, path = output_line.split(' ', 2)

          next if require_path && path.to_s.empty?

          sha
        end.reject(&:nil?)
      end
    end
  end
end
