# frozen_string_literal: true

class ServiceResponse
  def self.success(message: nil, payload: {})
    new(status: :success, message: message, payload: payload)
  end

  def self.error(message:, payload: {}, http_status: nil)
    new(status: :error, message: message, payload: payload, http_status: http_status)
  end

  attr_reader :status, :message, :http_status, :payload

  def initialize(status:, message: nil, payload: {}, http_status: nil)
    self.status = status
    self.message = message
    self.payload = payload
    self.http_status = http_status
  end

  def success?
    status == :success
  end

  def error?
    status == :error
  end

  private

  attr_writer :status, :message, :http_status, :payload
end
