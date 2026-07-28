# frozen_string_literal: true

module WorkhorseRequest
  extend ActiveSupport::Concern

  include WorkhorseAuthenticatable

  included do
    before_action :verify_workhorse_api!
  end
end
