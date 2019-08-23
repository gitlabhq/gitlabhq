# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ProjectStage < ApplicationRecord
      include Analytics::CycleAnalytics::Stage

      validates :project, presence: true
      belongs_to :project

      alias_attribute :parent, :project
    end
  end
end
