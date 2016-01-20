module Projects
  class UpdateMirrorService < BaseService
    class Error < StandardError; end
    class UpdateError < Error; end

    def execute
      return false unless project.mirror?

      unless current_user.can?(:push_code_to_protected_branches, project)
        return error("The mirror user is not allowed to push code to all branches on this project.")
      end

      update_tags do
        project.fetch_mirror
      end

      update_branches

      success
    rescue Gitlab::Shell::Error, UpdateError => e
      error(e.message)
    end

    private

    def update_branches
      local_branches = repository.branches.each_with_object({}) { |branch, branches| branches[branch.name] = branch }

      repository.upstream_branches.each do |upstream_branch|
        name = upstream_branch.name

        local_branch = local_branches[name]

        if local_branch.nil?
          result = CreateBranchService.new(project, current_user).execute(name, upstream_branch.target)
          if result[:status] == :error
            raise UpdateError, result[:message]
          end
        elsif local_branch.target == upstream_branch.target
          # Already up to date
        elsif repository.diverged_from_upstream?(name)
          # Cannot be updated
        else
          begin
            repository.ff_merge(current_user, upstream_branch.target, name)
          rescue GitHooksService::PreReceiveError, Repository::CommitError => e
            raise UpdateError, e.message
          end
        end
      end
    end

    def update_tags(&block)
      old_tags = repository.tags.each_with_object({}) { |tag, tags| tags[tag.name] = tag }

      fetch_result = block.call
      return fetch_result unless fetch_result

      repository.expire_tags_cache

      tags = repository.tags

      tags.each do |tag|
        old_tag = old_tags[tag.name]
        old_tag_target = old_tag ? old_tag.target : Gitlab::Git::BLANK_SHA

        next if old_tag_target == tag.target

        GitTagPushService.new.execute(project, current_user, old_tag_target, tag.target, "#{Gitlab::Git::TAG_REF_PREFIX}#{tag.name}", mirror_update: true)
      end

      fetch_result
    end
  end
end
