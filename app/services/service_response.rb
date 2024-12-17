# frozen_string_literal: true

class ServiceResponse
  def self.success(message: nil, payload: {}, http_status: :ok)
    new(
      status: :success,
      message: message,
      payload: payload,
      http_status: http_status
    )
  end

  def self.error(message:, payload: {}, http_status: nil, reason: nil)
    new(
      status: :error,
      message: message,
      payload: payload,
      http_status: http_status,
      reason: reason
    )
  end

  # This is used to help wrap old service responses that were just hashes
  def self.from_legacy_hash(response)
    return response if response.is_a?(ServiceResponse)
    return ServiceResponse.new(**response) if response.is_a?(Hash)

    raise ArgumentError, "argument must be a ServiceResponse or a Hash"
  end

  attr_reader :status, :message, :http_status, :payload, :reason

  def initialize(status:, message: nil, payload: {}, http_status: nil, reason: nil)
    self.status = status
    self.message = message
    self.payload = payload
    self.http_status = http_status
    self.reason = reason
  end

  def log_and_raise_exception(as: StandardError, **extra_data)
    error_tracking(as) do |ex|
      Gitlab::ErrorTracking.log_and_raise_exception(ex, extra_data)
    end
  end

  def track_exception(as: StandardError, **extra_data)
    error_tracking(as) do |ex|
      Gitlab::ErrorTracking.track_exception(ex, extra_data)
    end
  end

  def track_and_raise_exception(as: StandardError, **extra_data)
    error_tracking(as) do |ex|
      Gitlab::ErrorTracking.track_and_raise_exception(ex, extra_data)
    end
  end

  def [](key)
    to_h[key]
  end

  def to_h
    (payload || {}).merge(
      status: status,
      message: message,
      http_status: http_status,
      reason: reason)
  end

  def deconstruct_keys(keys)
    to_h.slice(*keys)
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

  def cause
    ActiveSupport::StringInquirer.new(reason.to_s)
  end

  private

  attr_writer :status, :message, :http_status, :payload, :reason

  def error_tracking(error_klass)
    if error?
      ex = error_klass.new(message)
      yield ex
    end

    self
  end
end
