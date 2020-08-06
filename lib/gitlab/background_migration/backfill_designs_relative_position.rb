# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill `relative_position` column in `design_management_designs` table
    class BackfillDesignsRelativePosition
      # Define the issue model
      class Issue < ActiveRecord::Base
        self.table_name = 'issues'
      end

      # Define the design model
      class Design < ActiveRecord::Base
        include RelativePositioning if defined?(RelativePositioning)

        self.table_name = 'design_management_designs'

        def self.relative_positioning_query_base(design)
          where(issue_id: design.issue_id)
        end

        def self.relative_positioning_parent_column
          :issue_id
        end

        def self.move_nulls_to_start(designs)
          if defined?(super)
            super(designs)
          else
            logger.error "BackfillDesignsRelativePosition failed because move_nulls_to_start is no longer included in the RelativePositioning concern"
          end
        end
      end

      def perform(issue_ids)
        issue_ids.each do |issue_id|
          migrate_issue(issue_id)
        end
      end

      private

      def migrate_issue(issue_id)
        issue = Issue.find_by(id: issue_id)
        return unless issue

        designs = Design.where(issue_id: issue.id).order(:id)
        return unless designs.any?

        Design.move_nulls_to_start(designs)
      end
    end
  end
end
