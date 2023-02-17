# frozen_string_literal: true

module Gitlab
  module Ci
    module ResourceGroups
      class Logger < ::Gitlab::JsonLogger
        def self.file_name_noext
          'ci_resource_groups_json'
        end
      end
    end
  end
end
