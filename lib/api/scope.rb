# Encapsulate a scope used for authorization, such as `api`, or `read_user`
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
      scopes.include?(self.name) && verify_if_condition(request)
    end

    private

    def verify_if_condition(request)
      self.if.nil? || self.if.call(request)
    end
  end
end
