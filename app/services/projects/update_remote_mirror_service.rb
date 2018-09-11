# frozen_string_literal: true

module Projects
  class UpdateRemoteMirrorService < BaseService
    attr_reader :errors

    def execute(remote_mirror)
      return success unless remote_mirror.enabled?

      errors = []

      begin
        remote_mirror.ensure_remote!
        repository.fetch_remote(remote_mirror.remote_name, no_tags: true)
        project.update_root_ref(remote_mirror.remote_name)

        opts = {}
        if remote_mirror.only_protected_branches?
          opts[:only_branches_matching] = project.protected_branches.select(:name).map(&:name)
        end

        remote_mirror.update_repository(opts)
      rescue => e
        errors << e.message.strip
      end

      if errors.present?
        error(errors.join("\n\n"))
      else
        success
      end
    end
  end
end
