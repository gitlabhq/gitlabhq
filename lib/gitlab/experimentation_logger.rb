# frozen_string_literal: true

module Gitlab
  class ExperimentationLogger < ::Gitlab::JsonLogger
    def self.file_name_noext
      'experimentation_json'
    end
  end
end
