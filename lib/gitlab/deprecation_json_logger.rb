# frozen_string_literal: true

module Gitlab
  class DeprecationJsonLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'deprecation_json'
    end
  end
end
