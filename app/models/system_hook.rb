# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string(255)      default("ProjectHook")
#  service_id :integer
#

class SystemHook < WebHook
  def self.all_hooks_fire(data)
    SystemHook.all.each do |sh|
      sh.async_execute data
    end
  end

  def async_execute(data)
    Sidekiq::Client.enqueue(SystemHookWorker, id, data)
  end
end
