module Projects
  class UpdateRemoteMirrorService < BaseService
    attr_reader :mirror, :errors

    def execute(remote_mirror)
      @mirror = remote_mirror
      @errors = []

      begin
        repository.fetch_remote(mirror.ref_name)

        if divergent_branches.present?
          errors << "The following branches have diverged from their local counterparts: #{divergent_branches.to_sentence}"
        end

        push_to_mirror if changed_branches.present?
        delete_from_mirror if deleted_branches.present?
      rescue Gitlab::Shell::Error => e
        errors << e.message.strip
      end

      if errors.present?
        error(errors.join("\n\n"))
      else
        success
      end
    end

    private

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

    def deleted_branches
      @deleted_branches ||= remote_branches.each_with_object([]) do |(name, branch), branches|
        local_branch = local_branches[name]

        if local_branch.nil? && project.commit(branch.target)
          branches << name
        end
      end
    end

    def push_to_mirror
      default_branch, branches = changed_branches.partition { |name| project.default_branch == name }

      # Push the default branch first so it works fine when remote mirror is empty.
      branches.unshift(*default_branch)

      repository.push_branches(project.path_with_namespace, mirror.ref_name, branches)
    end

    def delete_from_mirror
      repository.delete_remote_branches(project.path_with_namespace, mirror.ref_name, deleted_branches)
    end

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

    def divergent_branches
      remote_branches.each_with_object([]) do |(name, branch), branches|
        if local_branches[name] && repository.upstream_has_diverged?(name, mirror.ref_name)
          branches << name
        end
      end
    end

  end
end
