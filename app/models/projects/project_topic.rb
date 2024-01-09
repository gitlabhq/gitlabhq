# frozen_string_literal: true

module Projects
  class ProjectTopic < ApplicationRecord
    belongs_to :project
    belongs_to :topic, counter_cache: :total_projects_count

    validates :topic_id, uniqueness: { scope: [:project_id] }
  end
end
