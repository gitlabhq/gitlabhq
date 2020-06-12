# frozen_string_literal: true

class ProjectMetricsSetting < ApplicationRecord
  belongs_to :project

  validates :external_dashboard_url,
    allow_nil: true,
    length: { maximum: 255 },
    addressable_url: { enforce_sanitization: true, ascii_only: true }

  enum dashboard_timezone: { local: 0, utc: 1 }

  def dashboard_timezone=(val)
    super(val&.downcase)
  end
end
