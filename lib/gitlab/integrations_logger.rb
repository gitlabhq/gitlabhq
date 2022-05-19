# frozen_string_literal: true

module Gitlab
  class IntegrationsLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'integrations_json'
    end
  end
end
