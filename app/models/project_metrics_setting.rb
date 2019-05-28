# frozen_string_literal: true

class ProjectMetricsSetting < ApplicationRecord
  belongs_to :project

  validates :external_dashboard_url,
    length: { maximum: 255 },
    addressable_url: { enforce_sanitization: true, ascii_only: true }
end
