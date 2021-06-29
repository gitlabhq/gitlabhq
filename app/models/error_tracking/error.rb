# frozen_string_literal: true

class ErrorTracking::Error < ApplicationRecord
  belongs_to :project

  has_many :events, class_name: 'ErrorTracking::ErrorEvent'

  validates :project, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :actor, presence: true
end
