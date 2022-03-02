# frozen_string_literal: true

# Overrides `#serializable_hash` to raise an exception when called without the `only` option
# in order to prevent accidentally exposing attributes.
#
# An `unsafe: true` option can also be passed in to bypass this check.
#
# `#serializable_hash` is used by ActiveModel serializers like `ActiveModel::Serializers::JSON`
# which overrides `#as_json` and `#to_json`.
#
module BlocksUnsafeSerialization
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  UnsafeSerializationError = Class.new(StandardError)

  override :serializable_hash
  def serializable_hash(options = nil)
    return super if allow_serialization?(options)

    raise UnsafeSerializationError,
      "Serialization has been disabled on #{self.class.name}"
  end

  private

  def allow_serialization?(options = nil)
    return false unless options

    !!(options[:only] || options[:unsafe])
  end
end
