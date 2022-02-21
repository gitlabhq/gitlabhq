# frozen_string_literal: true

class SecurityReportsMrWidgetPromptExperiment < ApplicationExperiment
  control { }
  candidate { }

  def publish(_result = nil)
    super

    publish_to_database
  end
end
