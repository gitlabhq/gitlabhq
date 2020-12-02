# frozen_string_literal: true

class Feature
  class Logger < ::Gitlab::JsonLogger
    def self.file_name_noext
      'features_json'
    end
  end
end
