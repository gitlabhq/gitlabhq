# frozen_string_literal: true

# Overrides `as_json` and `to_json` to raise an exception when called in order
# to prevent accidentally exposing attributes
#
# Not that would ever happen... but just in case.
module BlocksJsonSerialization
  extend ActiveSupport::Concern

  JsonSerializationError = Class.new(StandardError)

  def to_json(*)
    raise JsonSerializationError,
      "JSON serialization has been disabled on #{self.class.name}"
  end

  alias_method :as_json, :to_json
end
