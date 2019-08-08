# frozen_string_literal: true

module Gitlab
  class GitLogger < JsonLogger
    def self.file_name_noext
      'git_json'
    end
  end
end
