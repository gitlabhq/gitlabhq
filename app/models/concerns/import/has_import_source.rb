# frozen_string_literal: true

module Import
  module HasImportSource
    extend ActiveSupport::Concern

    IMPORT_SOURCES = {
      none: 0, # not imported
      gitlab_migration: 1, # aka direct transfer & bulk_import
      gitlab_project: 2, # aka gitlab import/export
      github: 3,
      bitbucket: 4, # aka bitbucket cloud
      bitbucket_server: 5,
      fogbugz: 6,
      gitea: 7,
      git: 8, # aka repository by url
      manifest: 9, # aka manifest file
      custom_template: 10 # aka gitlab custom project template export
    }.freeze

    included do
      enum imported_from: IMPORT_SOURCES, _prefix: :imported_from
    end

    def imported?
      !imported_from_none?
    end
  end
end
