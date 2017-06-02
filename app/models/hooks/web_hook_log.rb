class WebHookLog < ActiveRecord::Base
  belongs_to :web_hook

  serialize :request_headers, Hash # rubocop:disable Cop/ActiverecordSerialize
  serialize :request_data, Hash # rubocop:disable Cop/ActiverecordSerialize
  serialize :response_headers, Hash # rubocop:disable Cop/ActiverecordSerialize

  validates :web_hook, presence: true

  def success?
    response_status =~ /^2/
  end
end
