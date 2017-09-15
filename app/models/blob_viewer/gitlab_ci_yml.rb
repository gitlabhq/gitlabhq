module BlobViewer
  class GitlabCiYml < Base
    include ServerSide
    include Auxiliary

    self.partial_name = 'gitlab_ci_yml'
    self.loading_partial_name = 'gitlab_ci_yml_loading'
    self.file_types = %i(gitlab_ci)
    self.binary = false

    def validation_message
      return @validation_message if defined?(@validation_message)

      prepare!

      @validation_message = Gitlab::Ci::YamlProcessor.validation_message(blob.data)
    end

    def valid?
      validation_message.blank?
    end
  end
end
