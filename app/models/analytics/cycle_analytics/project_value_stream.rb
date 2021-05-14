# frozen_string_literal: true

class Analytics::CycleAnalytics::ProjectValueStream < ApplicationRecord
  belongs_to :project

  has_many :stages, class_name: 'Analytics::CycleAnalytics::ProjectStage'

  validates :project, :name, presence: true
  validates :name, length: { minimum: 3, maximum: 100, allow_nil: false }, uniqueness: { scope: :project_id }

  def custom?
    false
  end

  def stages
    []
  end

  def self.build_default_value_stream(project)
    new(name: Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME, project: project)
  end
end
