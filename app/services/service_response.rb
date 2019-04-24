# frozen_string_literal: true

class ServiceResponse
  def self.success(message: nil)
    new(status: :success, message: message)
  end

  def self.error(message:, http_status: nil)
    new(status: :error, message: message, http_status: http_status)
  end

  attr_reader :status, :message, :http_status

  def initialize(status:, message: nil, http_status: nil)
    self.status = status
    self.message = message
    self.http_status = http_status
  end

  def success?
    status == :success
  end

  def error?
    status == :error
  end

  private

  attr_writer :status, :message, :http_status
end
