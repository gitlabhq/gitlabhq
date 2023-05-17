# frozen_string_literal: true

class ServiceHook < WebHook
  include Presentable

  extend ::Gitlab::Utils::Override

  belongs_to :integration
  validates :integration, presence: true

  def execute(data, hook_name = 'service_hook')
    super(data, hook_name)
  end

  override :parent
  delegate :parent, to: :integration
end
