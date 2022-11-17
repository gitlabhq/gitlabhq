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
end
