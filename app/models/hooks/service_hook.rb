# == Schema Information
#
# Table name: web_hooks
#
#  id                      :integer          not null, primary key
#  url                     :string(255)
#  project_id              :integer
#  created_at              :datetime
#  updated_at              :datetime
#  type                    :string(255)      default("ProjectHook")
#  service_id              :integer
#  push_events             :boolean          default(TRUE), not null
#  issues_events           :boolean          default(FALSE), not null
#  merge_requests_events   :boolean          default(FALSE), not null
#  tag_push_events         :boolean          default(FALSE)
#  note_events             :boolean          default(FALSE), not null
#  enable_ssl_verification :boolean          default(TRUE)
#

class ServiceHook < WebHook
  belongs_to :service

  def execute(data)
    super(data, 'service_hook')
  end
end
