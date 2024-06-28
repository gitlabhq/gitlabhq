# frozen_string_literal: true

module Import
  SOURCE_DIRECT_TRANSFER = :gitlab_migration # aka BulkImports
  SOURCE_PROJECT_EXPORT_IMPORT = :gitlab_project
  SOURCE_GROUP_EXPORT_IMPORT = :gitlab_group
  SOURCE_BITBUCKET_SERVER = :bitbucket_server

  module HasImportSource
    extend ActiveSupport::Concern

    IMPORT_SOURCES = {
      none: 0, # not imported
      SOURCE_DIRECT_TRANSFER => 1,
      SOURCE_PROJECT_EXPORT_IMPORT => 2,
      SOURCE_GROUP_EXPORT_IMPORT => 3,
      github: 4,
      bitbucket: 5, # aka bitbucket cloud
      SOURCE_BITBUCKET_SERVER => 6,
      fogbugz: 7,
      gitea: 8,
      git: 9, # aka repository by url
      manifest: 10, # aka manifest file
      custom_template: 11 # aka gitlab custom project template export
    }.freeze

    included do
      enum imported_from: IMPORT_SOURCES, _prefix: :imported_from
    end

    def imported?
      !imported_from_none?
    end
  end
end
