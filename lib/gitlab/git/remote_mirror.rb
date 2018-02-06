module Gitlab
  module Git
    class RemoteMirror
      def initialize(repository, ref_name)
        @repository = repository
        @ref_name = ref_name
      end

      def update(only_branches_matching: [])
        @repository.gitaly_migrate(:remote_update_remote_mirror) do |is_enabled|
          if is_enabled
            gitaly_update(only_branches_matching)
          else
            rugged_update(only_branches_matching)
          end
        end
      end

      private

      def gitaly_update(only_branches_matching)
        @repository.gitaly_remote_client.update_remote_mirror(@ref_name, only_branches_matching)
      end

      def rugged_update(only_branches_matching)
        local_branches = refs_obj(@repository.local_branches, only_refs_matching: only_branches_matching)
        remote_branches = refs_obj(@repository.remote_branches(@ref_name), only_refs_matching: only_branches_matching)

        updated_branches = changed_refs(local_branches, remote_branches)
        push_branches(updated_branches.keys) if updated_branches.present?

        delete_refs(local_branches, remote_branches)

        local_tags = refs_obj(@repository.tags)
        remote_tags = refs_obj(@repository.remote_tags(@ref_name))

        updated_tags = changed_refs(local_tags, remote_tags)
        @repository.push_remote_branches(@ref_name, updated_tags.keys) if updated_tags.present?

        delete_refs(local_tags, remote_tags)
      end

      def refs_obj(refs, only_refs_matching: [])
        refs.each_with_object({}) do |ref, refs|
          next if only_refs_matching.present? && !only_refs_matching.include?(ref.name)

          refs[ref.name] = ref
        end
      end

      def changed_refs(local_refs, remote_refs)
        local_refs.select do |ref_name, ref|
          remote_ref = remote_refs[ref_name]

          remote_ref.nil? || ref.dereferenced_target != remote_ref.dereferenced_target
        end
      end

      def push_branches(branches)
        default_branch, branches = branches.partition do |branch|
          @repository.root_ref == branch
        end

        # Push the default branch first so it works fine when remote mirror is empty.
        branches.unshift(*default_branch)

        @repository.push_remote_branches(@ref_name, branches)
      end

      def delete_refs(local_refs, remote_refs)
        refs = refs_to_delete(local_refs, remote_refs)

        @repository.delete_remote_branches(@ref_name, refs.keys) if refs.present?
      end

      def refs_to_delete(local_refs, remote_refs)
        default_branch_id = @repository.commit.id

        remote_refs.select do |remote_ref_name, remote_ref|
          next false if local_refs[remote_ref_name] # skip if branch or tag exist in local repo

          remote_ref_id = remote_ref.dereferenced_target.try(:id)

          remote_ref_id && @repository.rugged_is_ancestor?(remote_ref_id, default_branch_id)
        end
      end
    end
  end
end
