# frozen_string_literal: true

# Grape 2.4 (via mustermann-grape 1.1.0; ruby-grape/grape#2379) feeds declared
# parameter *types* into route matching: a `type: Integer` path parameter
# compiles to a digits-only route segment. A request whose segment is not all
# digits (a signed integer such as `-1`, or a non-numeric value such as `abc`)
# then fails to match the route, and Grape returns a generic
# `{"error":"404 Not Found"}` before parameter validation or the endpoint runs.
#
# Grape 2.0 built route captures only from explicit `requirements`, format and
# version (never from declared param types), so such requests reached
# validation (`400 ... is invalid` for malformed values) and the endpoint (its
# own `not_found!` message for valid-but-missing records). Hundreds of GitLab
# endpoints declare `type: Integer` path parameters and rely on that behaviour.
#
# This patch restores the Grape 2.0 routing semantics by not forwarding declared
# param types to Mustermann when the route pattern is built. Parameter
# validation is unaffected (the value is still coerced and validated after
# routing), so only route matching changes.
#
# The override mirrors the arguments of Grape::Router::Pattern#build_pattern
# (path, params, format, version, requirements) and passes an empty params hash
# to `super`. The guard makes it a no-op on Grape < 2.4 (which has no
# `build_pattern`), so it is safe in the dual-boot Gemfile/Gemfile.next setup.
if defined?(Grape::Router::Pattern) &&
    Grape::Router::Pattern.private_method_defined?(:build_pattern)
  module GrapeRouterPatternPatch
    private

    # The positional signature here is pinned to Grape 2.4's private method;
    # if the signature changes in a future Grape version, this guard will fail
    def build_pattern(path, _params, format, version, requirements)
      super(path, {}, format, version, requirements)
    end
  end

  Grape::Router::Pattern.prepend(GrapeRouterPatternPatch)
end
