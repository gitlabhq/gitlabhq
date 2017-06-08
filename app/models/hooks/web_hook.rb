class WebHook < ActiveRecord::Base
  include Sortable

  default_value_for :push_events, true
  default_value_for :issues_events, false
  default_value_for :confidential_issues_events, false
  default_value_for :note_events, false
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false
  default_value_for :job_events, false
  default_value_for :pipeline_events, false
  default_value_for :repository_update_events, false
  default_value_for :enable_ssl_verification, true

  has_many :web_hook_logs, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent

  scope :push_hooks, -> { where(push_events: true) }
  scope :tag_push_hooks, -> { where(tag_push_events: true) }

  validates :url, presence: true, url: true

  def execute(data, hook_name)
    WebHookService.new(self, data, hook_name).execute
  end

  def async_execute(data, hook_name)
    WebHookService.new(self, data, hook_name).async_execute
  end
end
