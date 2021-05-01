# frozen_string_literal: true

class ServiceResponse
  def self.success(message: nil, payload: {}, http_status: :ok)
    new(status: :success, message: message, payload: payload, http_status: http_status)
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

  def [](key)
    to_h[key]
  end

  def to_h
    (payload || {}).merge(status: status, message: message, http_status: http_status)
  end

  def success?
    status == :success
  end

  def error?
    status == :error
  end

  def errors
    return [] unless error?

    Array.wrap(message)
  end

  private

  attr_writer :status, :message, :http_status, :payload
end
