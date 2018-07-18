module Gitlab
  module Git
    module RepositoryMirroring
      REFMAPS = {
        # With `:all_refs`, the repository is equivalent to the result of `git clone --mirror`
        all_refs: '+refs/*:refs/*',
        heads: '+refs/heads/*:refs/heads/*',
        tags: '+refs/tags/*:refs/tags/*'
      }.freeze

      RemoteError = Class.new(StandardError)

      def set_remote_as_mirror(remote_name, refmap: :all_refs)
        set_remote_refmap(remote_name, refmap)

        rugged.config["remote.#{remote_name}.mirror"] = true
        rugged.config["remote.#{remote_name}.prune"] = true
      end

      def remote_branches(remote_name)
        gitaly_migrate(:ref_find_all_remote_branches) do |is_enabled|
          if is_enabled
            gitaly_ref_client.remote_branches(remote_name)
          else
            rugged_remote_branches(remote_name)
          end
        end
      end

      private

      def rugged_remote_branches(remote_name)
        branches = []

        rugged.references.each("refs/remotes/#{remote_name}/*").map do |ref|
          name = ref.name.sub(%r{\Arefs/remotes/#{remote_name}/}, '')

          begin
            target_commit = Gitlab::Git::Commit.find(self, ref.target.oid)
            branches << Gitlab::Git::Branch.new(self, name, ref.target, target_commit)
          rescue Rugged::ReferenceError
            # Omit invalid branch
          end
        end

        branches
      end

      def set_remote_refmap(remote_name, refmap)
        Array(refmap).each_with_index do |refspec, i|
          refspec = REFMAPS[refspec] || refspec

          # We need multiple `fetch` entries, but Rugged only allows replacing a config, not adding to it.
          # To make sure we start from scratch, we set the first using rugged, and use `git` for any others
          if i == 0
            rugged.config["remote.#{remote_name}.fetch"] = refspec
          else
            run_git(%W[config --add remote.#{remote_name}.fetch #{refspec}])
          end
        end
      end
    end
  end
end
