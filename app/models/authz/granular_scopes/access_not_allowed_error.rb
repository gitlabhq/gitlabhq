# frozen_string_literal: true

module Authz
  module GranularScopes
    # Raised by an owner's boundary rule for an access level it never allows
    AccessNotAllowedError = Class.new(StandardError)
  end
end
