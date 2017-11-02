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
      # Can return a lazy enumerator to limit work done on megabytes of data
      def new_objects(require_path: nil, lazy: false, not_in: nil)
        object_output = execute([*base_args, newrev, *not_in_refs(not_in), '--objects'])

        objects_from_output(object_output, require_path: require_path, lazy: lazy)
      end

      def all_objects(require_path: nil)
        object_output = execute([*base_args, '--all', '--objects'])

        objects_from_output(object_output, require_path: require_path, lazy: true)
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

      def base_args
        [
          Gitlab.config.git.bin_path,
          "--git-dir=#{path_to_repo}",
          'rev-list'
        ]
      end

      def objects_from_output(object_output, require_path: nil, lazy: nil)
        objects = object_output.lazy.map do |output_line|
          sha, path = output_line.split(' ', 2)

          next if require_path && path.blank?

          sha
        end.reject(&:nil?)

        if lazy
          objects
        else
          objects.force
        end
      end
    end
  end
end
