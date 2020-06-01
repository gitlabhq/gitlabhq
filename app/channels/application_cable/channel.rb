# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    include Logging

    private

    def notification_payload(_)
      super.merge!(params: params.except(:channel))
    end

    def request
      connection.request
    end
  end
end
