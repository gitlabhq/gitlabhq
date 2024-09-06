# frozen_string_literal: true

module BlobViewer
  class GitlabCiYml < Base
    include ServerSide
    include Auxiliary

    self.partial_name = 'gitlab_ci_yml'
    self.loading_partial_name = 'gitlab_ci_yml_loading'
    self.binary = false

    # rubocop:disable Lint/UnusedMethodArgument -- The keyword argument is required by the parent class but not here.
    def self.can_render?(blob, verify_binary: true)
      blob.path == blob.project.ci_config_path_or_default
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def validation_message(opts)
      return @validation_message if defined?(@validation_message)

      prepare!

      @validation_message = Gitlab::Ci::Lint
        .new(project: opts[:project], current_user: opts[:user], sha: opts[:sha], verify_project_sha: false)
        .validate(blob.data).errors.first
    end

    def valid?(opts)
      validation_message(opts).blank?
    end

    def visible_to?(_current_user, ref)
      # By checking if the ref is a branch or tag, we can avoid verifying the `sha` when calling `Ci::Lint`.
      project.repository.branch_or_tag?(ref)
    end
  end
end
