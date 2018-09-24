# frozen_string_literal: true

module BlobViewer
  class GitlabCiYml < Base
    include ServerSide
    include Auxiliary

    self.partial_name = 'gitlab_ci_yml'
    self.loading_partial_name = 'gitlab_ci_yml_loading'
    self.file_types = %i(gitlab_ci)
    self.binary = false

    def validation_message(project, sha)
      return @validation_message if defined?(@validation_message)

      prepare!

      @validation_message = Gitlab::Ci::YamlProcessor.validation_message(blob.data, { project: project, sha: sha })
    end

    def valid?(project, sha)
      validation_message(project, sha).blank?
    end
  end
end
