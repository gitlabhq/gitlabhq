# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ProjectStage < ApplicationRecord
      include Analytics::CycleAnalytics::Stage

      validates :project, presence: true
      belongs_to :project

      alias_attribute :parent, :project
      alias_attribute :parent_id, :project_id

      def self.relative_positioning_query_base(stage)
        where(project_id: stage.project_id)
      end

      def self.relative_positioning_parent_column
        :project_id
      end
    end
  end
end
