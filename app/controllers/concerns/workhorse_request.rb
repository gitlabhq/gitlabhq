# frozen_string_literal: true

module WorkhorseRequest
  extend ActiveSupport::Concern

  included do
    before_action :verify_workhorse_api!
  end

  private

  def verify_workhorse_api!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end
end
