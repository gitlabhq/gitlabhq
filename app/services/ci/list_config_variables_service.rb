# frozen_string_literal: true

module Ci
  class ListConfigVariablesService < ::BaseService
    def execute(sha)
      config = project.ci_config_for(sha)
      return {} unless config

      result = Gitlab::Ci::YamlProcessor.new(config).execute
      result.valid? ? result.variables_with_data : {}
    end
  end
end
