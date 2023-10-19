# frozen_string_literal: true

module Ci::TriggersHelper
  def builds_trigger_url(project_id, ref: nil)
    if ref.nil?
      "#{Settings.gitlab.url}/api/v4/projects/#{project_id}/trigger/pipeline"
    else
      "#{Settings.gitlab.url}/api/v4/projects/#{project_id}/ref/#{ref}/trigger/pipeline"
    end
  end

  def integration_trigger_url(integration)
    "#{Settings.gitlab.url}/api/v4/projects/#{integration.project_id}/integrations/#{integration.to_param}/trigger"
  end
end
