# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  type       :string(255)      default("ProjectHook")
#  service_id :integer
#

class SystemHook < WebHook
end
