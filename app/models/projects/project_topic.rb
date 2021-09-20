# frozen_string_literal: true

module Projects
  class ProjectTopic < ApplicationRecord
    belongs_to :project
    belongs_to :topic
  end
end
