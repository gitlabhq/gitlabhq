module BlobViewer
  class GitlabCiYml < Base
    include ServerSide
    include Auxiliary

    self.partial_name = 'gitlab_ci_yml'
    self.loading_partial_name = 'gitlab_ci_yml_loading'
    self.file_type = :gitlab_ci
    self.binary = false

    def validation_message
      return @validation_message if defined?(@validation_message)

      prepare!

      @validation_message = Ci::GitlabCiYamlProcessor.validation_message(blob.data)
    end

    def valid?
      validation_message.blank?
    end
  end
end
