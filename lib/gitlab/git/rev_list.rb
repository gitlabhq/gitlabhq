# Gitaly note: JV: will probably be migrated indirectly by migrating the call sites.

module Gitlab
  module Git
    class RevList
      include Gitlab::Git::Popen

      attr_reader :oldrev, :newrev, :path_to_repo

      def initialize(path_to_repo:, newrev:, oldrev: nil)
        @oldrev = oldrev
        @newrev = newrev
        @path_to_repo = path_to_repo
      end

      # This method returns an array of new commit references
      def new_refs
        execute([*base_args, newrev, '--not', '--all'])
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
        args = [*base_args, newrev, *not_in_refs(not_in), '--objects']

        get_objects(args, require_path: require_path, &lazy_block)
      end

      def all_objects(require_path: nil, &lazy_block)
        args = [*base_args, '--all', '--objects']

        get_objects(args, require_path: require_path, &lazy_block)
      end

      # This methods returns an array of missed references
      #
      # Should become obsolete after https://gitlab.com/gitlab-org/gitaly/issues/348.
      def missed_ref
        execute([*base_args, '--max-count=1', oldrev, "^#{newrev}"])
      end

      private

      def not_in_refs(references)
        return ['--not', '--all'] unless references
        return [] if references.empty?

        references.prepend('--not')
      end

      def execute(args)
        output, status = popen(args, nil, Gitlab::Git::Env.to_env_hash)

        unless status.zero?
          raise "Got a non-zero exit code while calling out `#{args.join(' ')}`: #{output}"
        end

        output.split("\n")
      end

      def lazy_execute(args, &lazy_block)
        popen(args, nil, Gitlab::Git::Env.to_env_hash, lazy_block: lazy_block)
      end

      def base_args
        [
          Gitlab.config.git.bin_path,
          "--git-dir=#{path_to_repo}",
          'rev-list'
        ]
      end

      def get_objects(args, require_path: nil)
        if block_given?
          lazy_execute(args) do |lazy_output|
            objects = objects_from_output(lazy_output, require_path: require_path)

            yield(objects)
          end
        else
          object_output = execute(args)

          objects_from_output(object_output, require_path: require_path)
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
