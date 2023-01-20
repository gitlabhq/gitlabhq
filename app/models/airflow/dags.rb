# frozen_string_literal: true

module Airflow
  class Dags < ApplicationRecord
    belongs_to :project

    validates :project, presence: true
    validates :dag_name, length: { maximum: 255 }, presence: true
    validates :schedule, length: { maximum: 255 }
    validates :fileloc, length: { maximum: 255 }

    scope :by_project_id, ->(project_id) { where(project_id: project_id).order(id: :asc) }
  end
end
