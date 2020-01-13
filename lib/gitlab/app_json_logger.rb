# frozen_string_literal: true

module Gitlab
  class AppJsonLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'application_json'
    end
  end
end
