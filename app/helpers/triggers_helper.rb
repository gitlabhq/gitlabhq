module TriggersHelper
  def builds_trigger_url(project_id, ref: nil)
    if ref.nil?
      "#{Settings.gitlab.url}/api/v3/projects/#{project_id}/trigger/builds"
    else
      "#{Settings.gitlab.url}/api/v3/projects/#{project_id}/ref/#{ref}/trigger/builds"
    end
  end
end
