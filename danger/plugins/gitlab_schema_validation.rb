# frozen_string_literal: true

require_relative '../../tooling/danger/gitlab_schema_validation_suggestion'

module Danger
  class GitlabSchemaValidation < ::Danger::Plugin
    include Tooling::Danger::GitlabSchemaValidationSuggestion
  end
end
