# frozen_string_literal: true

module Gitlab
  class DeprecationJsonLogger < Gitlab::JsonLogger
    exclude_context!

    def self.file_name_noext
      'deprecation_json'
    end
  end
end
