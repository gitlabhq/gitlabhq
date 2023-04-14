# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class LabelsImporter
        include BulkImporting

        # rubocop: disable CodeReuse/ActiveRecord
        def existing_labels
          @existing_labels ||= project.labels.pluck(:title).to_set
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def execute
          rows, validation_errors = build_labels

          bulk_insert(rows)
          bulk_insert_failures(validation_errors) if validation_errors.any?
          build_labels_cache
        end

        def build_labels
          build_database_rows(each_label)
        end

        def already_imported?(label)
          existing_labels.include?(label[:name])
        end

        def build_labels_cache
          LabelFinder.new(project).build_cache
        end

        def build_attributes(label)
          time = Time.zone.now

          {
            title: label[:name],
            color: '#' + label[:color],
            project_id: project.id,
            type: 'ProjectLabel',
            created_at: time,
            updated_at: time
          }
        end

        def each_label
          client.labels(project.import_source)
        end

        def object_type
          :label
        end

        private

        def model
          Label
        end

        def github_identifiers(label)
          {
            title: label[:name],
            object_type: object_type
          }
        end
      end
    end
  end
end
