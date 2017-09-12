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

      # This method returns an array of new references
      def new_refs
        execute([*base_args, newrev, '--not', '--all'])
      end

      # This methods returns an array of missed references
      #
      # Should become obsolete after https://gitlab.com/gitlab-org/gitaly/issues/348.
      def missed_ref
        execute([*base_args, '--max-count=1', oldrev, "^#{newrev}"])
      end

      private

      def execute(args)
        output, status = popen(args, nil, Gitlab::Git::Env.all.stringify_keys)

        unless status.zero?
          raise "Got a non-zero exit code while calling out `#{args.join(' ')}`."
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
    end
  end
end
