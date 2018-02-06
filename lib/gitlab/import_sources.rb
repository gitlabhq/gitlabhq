# Gitlab::ImportSources module
#
# Define import sources that can be used
# during the creation of new project
#
module Gitlab
  module ImportSources
    ImportSource = Struct.new(:name, :title, :importer)

    # We exclude `bare_repository` here as it has no import class associated
    ImportTable = [
      ImportSource.new('github',         'GitHub',        Gitlab::GithubImport::ParallelImporter),
      ImportSource.new('bitbucket',      'Bitbucket',     Gitlab::BitbucketImport::Importer),
      ImportSource.new('gitlab',         'GitLab.com',    Gitlab::GitlabImport::Importer),
      ImportSource.new('google_code',    'Google Code',   Gitlab::GoogleCodeImport::Importer),
      ImportSource.new('fogbugz',        'FogBugz',       Gitlab::FogbugzImport::Importer),
      ImportSource.new('git',            'Repo by URL',   nil),
      ImportSource.new('gitlab_project', 'GitLab export', Gitlab::ImportExport::Importer),
      ImportSource.new('gitea',          'Gitea',         Gitlab::LegacyGithubImport::Importer)
    ].freeze

    class << self
      def options
        @options ||= Hash[ImportTable.map { |importer| [importer.title, importer.name] }]
      end

      def values
        @values ||= ImportTable.map(&:name)
      end

      def importer_names
        @importer_names ||= ImportTable.select(&:importer).map(&:name)
      end

      def importer(name)
        ImportTable.find { |import_source| import_source.name == name }.importer
      end

      def title(name)
        options.key(name)
      end
    end
  end
end
