module TriggersHelper
  def builds_trigger_url(project_id)
    "#{Settings.gitlab.url}/api/v3/projects/#{project_id}/trigger/builds"
  end
end
