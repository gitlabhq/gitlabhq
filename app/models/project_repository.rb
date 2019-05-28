# frozen_string_literal: true

class ProjectRepository < ApplicationRecord
  include Shardable

  belongs_to :project, inverse_of: :project_repository

  class << self
    def find_project(disk_path)
      find_by(disk_path: disk_path)&.project
    end
  end
end
