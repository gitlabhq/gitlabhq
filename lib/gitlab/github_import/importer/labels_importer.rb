# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class LabelsImporter
        include BulkImporting

        attr_reader :project, :client, :existing_labels

        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(project, client)
          @project = project
          @client = client
          @existing_labels = project.labels.pluck(:title).to_set
        end

        def execute
          bulk_insert(Label, build_labels)
          build_labels_cache
        end

        def build_labels
          build_database_rows(each_label)
        end

        def already_imported?(label)
          existing_labels.include?(label.name)
        end

        def build_labels_cache
          LabelFinder.new(project).build_cache
        end

        def build(label)
          time = Time.zone.now

          {
            title: label.name,
            color: '#' + label.color,
            project_id: project.id,
            type: 'ProjectLabel',
            created_at: time,
            updated_at: time
          }
        end

        def each_label
          client.labels(project.import_source)
        end
      end
    end
  end
end
