# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class MilestonesImporter
        include BulkImporting

        # rubocop: disable CodeReuse/ActiveRecord
        def existing_milestones
          @existing_milestones ||= project.milestones.pluck(:iid).to_set
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def execute
          rows, validation_errors = build_milestones

          bulk_insert(rows)
          bulk_insert_failures(validation_errors) if validation_errors.any?
          build_milestones_cache
        end

        def build_milestones
          build_database_rows(each_milestone)
        end

        def already_imported?(milestone)
          existing_milestones.include?(milestone[:number])
        end

        def build_milestones_cache
          MilestoneFinder.new(project).build_cache
        end

        def build_attributes(milestone)
          {
            iid: milestone[:number],
            title: milestone[:title],
            description: milestone[:description],
            project_id: project.id,
            state: state_for(milestone),
            due_date: milestone[:due_on]&.to_date,
            created_at: milestone[:created_at],
            updated_at: milestone[:updated_at]
          }
        end

        def state_for(milestone)
          milestone[:state] == 'open' ? :active : :closed
        end

        def each_milestone
          client.milestones(project.import_source, state: 'all')
        end

        def object_type
          :milestone
        end

        private

        def model
          Milestone
        end

        def github_identifiers(milestone)
          {
            iid: milestone[:number],
            title: milestone[:title],
            object_type: object_type
          }
        end
      end
    end
  end
end
