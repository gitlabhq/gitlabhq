# frozen_string_literal: true

class ServiceHook < WebHook
  include Presentable

  belongs_to :integration, foreign_key: :service_id
  validates :integration, presence: true

  def execute(data, hook_name = 'service_hook')
    super(data, hook_name)
  end
end
