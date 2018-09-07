module Gitlab
  class ProjectServiceLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'integrations_json'
    end
  end
end
