module Projects
  class UpdateMirrorService < BaseService
    class FetchError < StandardError; end

    def execute
      return false unless project.mirror?

      begin
        update_tags do
          project.fetch_mirror
        end
      rescue Gitlab::Shell::Error => e
        raise FetchError, e.message
      end

      update_branches

      true
    end

    private

    def update_branches
      local_branches = repository.branches.each_with_object({}) { |branch, branches| branches[branch.name] = branch }

      repository.upstream_branches.each do |upstream_branch|
        name = upstream_branch.name

        local_branch = local_branches[name]

        if local_branch.nil?
          CreateBranchService.new(project, current_user).execute(name, upstream_branch.target)
        elsif local_branch.target == upstream_branch.target
          # Already up to date
        elsif repository.diverged_from_upstream?(name)
          # Cannot be updated
        else
          repository.ff_merge(current_user, upstream_branch.target, name)
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

        GitTagPushService.new.execute(project, current_user, old_tag_target, tag.target, "#{Gitlab::Git::TAG_REF_PREFIX}#{tag.name}")
      end

      fetch_result
    end
  end
end
