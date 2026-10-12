# frozen_string_literal: true

# Encapsulate a scope used for authorization, such as `api`, or `read_user`
# See Gitlab::Auth for the set of available scopes, and their purposes.
module API
  class Scope
    attr_reader :name, :if

    def initialize(name, options = {})
      @name = name.to_sym
      @if = options[:if]
    end

    # Are the `scopes` passed in sufficient to adequately authorize the passed
    # request for the scope represented by the current instance of this class?
    def sufficient?(scopes, request)
      scopes.include?(self.name) && applies_to?(request)
    end

    def to_s
      name.to_s
    end

    # Does the `if` condition this scope was registered with hold for the passed
    # request? A scope registered without a condition applies to every request.
    def applies_to?(request)
      self.if.nil? || self.if.call(request)
    end
  end
end
