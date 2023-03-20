# frozen_string_literal: true

class ProjectImportEntity < ProjectEntity
  include ImportHelper

  expose :import_source, documentation: { type: 'string', example: 'source/source-repo' }
  expose :import_status, documentation: {
    type: 'string', example: 'scheduled', values: %w[scheduled started finished failed canceled]
  }
  expose :human_import_status_name, documentation: { type: 'string', example: 'canceled' }

  expose :provider_link, documentation: { type: 'string', example: '/source/source-repo' } do |project, options|
    provider_project_link_url(options[:provider_url], project[:import_source])
  end

  expose :import_error, if: ->(project) { project.import_state&.failed? } do |project|
    project.import_failures.last&.exception_message
  end

  # Only for GitHub importer where we pass client through
  expose :relation_type do |project, options|
    next nil if options[:client].nil? || Feature.disabled?(:remove_legacy_github_client)

    ::Gitlab::GithubImport::ProjectRelationType.new(options[:client]).for(project.import_source)
  end
end
