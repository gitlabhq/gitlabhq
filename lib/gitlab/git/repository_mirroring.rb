module Gitlab
  module Git
    module RepositoryMirroring
      def remote_branches(remote_name)
        gitaly_migrate(:ref_find_all_remote_branches) do |is_enabled|
          if is_enabled
            gitaly_ref_client.remote_branches(remote_name)
          else
            Gitlab::GitalyClient::StorageSettings.allow_disk_access do
              rugged_remote_branches(remote_name)
            end
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
    end
  end
end
