module Gitlab
  module Git
    module RepositoryWorktree
      def fresh_worktree?(path)
        File.exist?(path) && !clean_stuck_worktree(path)
      end

      def with_worktree(path, target, env:)
        run_git!(%W(worktree add --detach #{path} #{target}), env: env)

        yield
      ensure
        FileUtils.rm_rf(path) if File.exist?(path)
      end

      def clean_stuck_worktree(path)
        return false unless File.mtime(path) < 15.minutes.ago

        FileUtils.rm_rf(path)
        true
      end
    end
  end
end
