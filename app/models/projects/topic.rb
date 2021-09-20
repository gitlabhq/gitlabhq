# frozen_string_literal: true

module Projects
  class Topic < ApplicationRecord
    validates :name, presence: true, uniqueness: true, length: { maximum: 255 }

    has_many :project_topics, class_name: 'Projects::ProjectTopic'
    has_many :projects, through: :project_topics
  end
end
