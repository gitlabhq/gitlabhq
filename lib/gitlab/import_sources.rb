# frozen_string_literal: true

# Gitlab::ImportSources module
#
# Define import sources that can be used
# during the creation of new project
module Gitlab
  module ImportSources
    ImportSource = Struct.new(:name, :title, :importer)

    IMPORT_TABLE = [
      ImportSource.new('github',           'GitHub',            Gitlab::GithubImport::ParallelImporter),
      ImportSource.new('bitbucket',        'Bitbucket Cloud',   Gitlab::BitbucketImport::ParallelImporter),
      ImportSource.new('bitbucket_server', 'Bitbucket Server',  Gitlab::BitbucketServerImport::ParallelImporter),
      ImportSource.new('fogbugz',          'FogBugz',           Gitlab::FogbugzImport::Importer),
      ImportSource.new('git',              'Repository by URL', nil),
      ImportSource.new('gitlab_project',   'GitLab export',     Gitlab::ImportExport::Importer),
      ImportSource.new('gitea',            'Gitea',             Gitlab::LegacyGithubImport::Importer),
      ImportSource.new('manifest',         'Manifest file',     nil)
    ].freeze

    class << self
      prepend_mod_with('Gitlab::ImportSources') # rubocop: disable Cop/InjectEnterpriseEditionModule

      def options
        import_table.to_h { |importer| [importer.title, importer.name] }
      end

      def values
        import_table.map(&:name)
      end

      def importer_names
        import_table.select(&:importer).map(&:name)
      end

      def importer(name)
        import_table.find { |import_source| import_source.name == name }.importer
      end

      def title(name)
        options.key(name)
      end

      def import_table
        IMPORT_TABLE
      end

      def map_import_source_names_to_ints_for_rows(resources)
        resources.each do |resource|
          next unless resource['imported_from']

          resource['imported_from'] = import_source_name_to_int(resource['imported_from'])
        end
      end

      def import_source_name_to_int(name)
        ::Import::HasImportSource::IMPORT_SOURCES[name.to_sym]
      end
    end
  end
end
