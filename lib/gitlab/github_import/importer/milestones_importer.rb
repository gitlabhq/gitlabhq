# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class MilestonesImporter
        include BulkImporting

        attr_reader :project, :client, :existing_milestones

        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(project, client)
          @project = project
          @client = client
          @existing_milestones = project.milestones.pluck(:iid).to_set
        end

        def execute
          bulk_insert(Milestone, build_milestones)
          build_milestones_cache
        end

        def build_milestones
          build_database_rows(each_milestone)
        end

        def already_imported?(milestone)
          existing_milestones.include?(milestone.number)
        end

        def build_milestones_cache
          MilestoneFinder.new(project).build_cache
        end

        def build(milestone)
          {
            iid: milestone.number,
            title: milestone.title,
            description: milestone.description,
            project_id: project.id,
            state: state_for(milestone),
            created_at: milestone.created_at,
            updated_at: milestone.updated_at
          }
        end

        def state_for(milestone)
          milestone.state == 'open' ? :active : :closed
        end

        def each_milestone
          client.milestones(project.import_source, state: 'all')
        end
      end
    end
  end
end
