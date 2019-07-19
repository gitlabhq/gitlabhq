# frozen_string_literal: true

module Gitlab
  class GitLogger < JsonLogger
    def self.file_name_noext
      'githost'
    end
  end
end
