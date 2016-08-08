module Projects
  class UpdateRemoteMirrorService < BaseService
    attr_reader :mirror, :errors

    def execute(remote_mirror)
      @mirror = remote_mirror
      @errors = []

      begin
        repository.fetch_remote(mirror.ref_name, no_tags: true)

        if divergent_branches.present?
          errors << "The following branches have diverged from their local counterparts: #{divergent_branches.to_sentence}"
        end

        push_branches if changed_branches.present?
        delete_branches if deleted_branches.present?

        push_tags if changed_tags.present?
        delete_tags if deleted_tags.present?
      rescue => e
        errors << e.message.strip
      end

      if errors.present?
        error(errors.join("\n\n"))
      else
        success
      end
    end

    private

    def local_branches
      @local_branches ||= repository.local_branches.each_with_object({}) do |branch, branches|
        branches[branch.name] = branch
      end
    end

    def remote_branches
      @remote_branches ||= repository.remote_branches(mirror.ref_name).each_with_object({}) do |branch, branches|
        branches[branch.name] = branch
      end
    end

    def push_branches
      default_branch, branches = changed_branches.partition { |name| project.default_branch == name }

      # Push the default branch first so it works fine when remote mirror is empty.
      branches.unshift(*default_branch)

      repository.push_remote_branches(mirror.ref_name, branches)
    end

    def delete_branches
      repository.delete_remote_branches(mirror.ref_name, deleted_branches)
    end

    def deleted_branches
      @deleted_branches ||= remote_branches.each_with_object([]) do |(name, branch), branches|
        local_branch = local_branches[name]

        if local_branch.nil? && project.commit(branch.target)
          branches << name
        end
      end
    end

    def changed_branches
      @changed_branches ||= local_branches.each_with_object([]) do |(name, branch), branches|
        remote_branch = remote_branches[name]

        if remote_branch.nil?
          branches << name
        elsif branch.target == remote_branch.target
          # Already up to date
        elsif !repository.upstream_has_diverged?(name, mirror.ref_name)
          branches << name
        end
      end
    end

    def divergent_branches
      remote_branches.each_with_object([]) do |(name, _), branches|
        if local_branches[name] && repository.upstream_has_diverged?(name, mirror.ref_name)
          branches << name
        end
      end
    end

    def local_tags
      @local_tags ||= repository.tags.each_with_object({}) do |tag, tags|
        tags[tag.name] = tag
      end
    end

    def remote_tags
      @remote_tags ||= repository.remote_tags(mirror.ref_name).each_with_object({}) do |tag, tags|
        tags[tag.name] = tag
      end
    end

    def push_tags
      repository.push_remote_branches(mirror.ref_name, changed_tags)
    end

    def delete_tags
      repository.delete_remote_branches(mirror.ref_name, deleted_tags)
    end

    def changed_tags
      @changed_tags ||= local_tags.each_with_object([]) do |(name, tag), tags|
        remote_tag = remote_tags[name]

        if remote_tag.nil? || (tag.target != remote_tag.target)
          tags << name
        end
      end
    end

    def deleted_tags
      @deleted_tags ||= remote_tags.each_with_object([]) do |(name, _), tags|
        tags << name if local_tags[name].nil?
      end
    end
  end
end
