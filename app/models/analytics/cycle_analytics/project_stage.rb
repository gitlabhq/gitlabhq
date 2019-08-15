# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class ProjectStage < ApplicationRecord
      belongs_to :project
    end
  end
end
