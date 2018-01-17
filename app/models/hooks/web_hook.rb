class WebHook < ActiveRecord::Base
  include Sortable

  has_many :web_hook_logs, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  validates :url, presence: true, url: true
  validates :token, format: { without: /\n/ }

  def execute(data, hook_name)
    WebHookService.new(self, data, hook_name).execute
  end

  def async_execute(data, hook_name)
    WebHookService.new(self, data, hook_name).async_execute
  end
end
