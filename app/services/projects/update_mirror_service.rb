module Projects
  class UpdateMirrorService < BaseService
    class Error < StandardError; end
    class UpdateError < Error; end

    def execute
      unless project.mirror?
        return error("The project has no mirror to update")
      end

      unless can?(current_user, :push_code_to_protected_branches, project)
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

      errors = []

      repository.upstream_branches.each do |upstream_branch|
        name = upstream_branch.name

        local_branch = local_branches[name]

        if local_branch.nil?
          result = CreateBranchService.new(project, current_user).execute(name, upstream_branch.target)
          if result[:status] == :error
            errors << result[:message]
          end
        elsif local_branch.target == upstream_branch.target
          # Already up to date
        elsif repository.diverged_from_upstream?(name)
          # Cannot be updated
          if name == project.default_branch
            errors << "The default branch (#{project.default_branch}) has diverged from its upstream counterpart and could not be updated automatically."
          end
        else
          begin
            repository.ff_merge(current_user, upstream_branch.target, name)
          rescue GitHooksService::PreReceiveError, Repository::CommitError => e
            errors << e.message
          end
        end
      end

      unless errors.empty?
        raise UpdateError, errors.join("\n\n")
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

        GitTagPushService.new(
          project,
          current_user,
          {
            oldrev: old_tag_target,
            newrev: tag.target,
            ref: "#{Gitlab::Git::TAG_REF_PREFIX}#{tag.name}",
            mirror_update: true
          }
        ).execute
      end

      fetch_result
    end
  end
end
