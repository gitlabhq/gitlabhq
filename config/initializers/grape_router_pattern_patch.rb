# frozen_string_literal: true

# Grape (via mustermann-grape; ruby-grape/grape#2379) feeds declared parameter
# *types* into route matching: a `type: Integer` path parameter compiles to a
# digits-only route segment. A request whose segment is not all digits (a signed
# integer such as `-1`, or a non-numeric value such as `abc`) then fails to match
# the route, and Grape returns a generic `{"error":"404 Not Found"}` before
# parameter validation or the endpoint runs.
#
# Hundreds of GitLab endpoints declare `type: Integer` path parameters and rely on
# the request reaching validation (`400 ... is invalid` for malformed values) and
# the endpoint (its own `not_found!` message for valid-but-missing records).
# Changing those responses would be a breaking REST API change.
#
# This patch keeps that contract by not forwarding declared param types to
# Mustermann when the route pattern is built. Parameter validation is unaffected
# (the value is still coerced and validated after routing), so only route matching
# changes.
#
# Grape moved that work between the versions this repo dual-boots (see the `next?`
# block in Gemfile): up to 3.0 it lives in the private `Pattern#build_pattern`, from
# 3.1 it is inlined into `Pattern#initialize`, which also takes keyword arguments.
# Both seams are kept so one initializer serves both versions. Prepending a method
# nothing calls is legal Ruby and silently does nothing, so a Grape that has moved
# the seam again raises rather than leaving the contract unenforced.
#
# Behaviour is pinned by spec/initializers/grape_router_pattern_patch_spec.rb.
module GrapeRouterPatternPatch
  if Gem::Version.new(Grape::VERSION) < Gem::Version.new('3.1')

    private

    def build_pattern(path, _params, format, version, requirements)
      super(path, {}, format, version, requirements)
    end
  # The version says which era of internals this is, but not that the seam is still
  # there, so confirm the keyword before overriding it. Required or optional both work.
  elsif Grape::Router::Pattern.instance_method(:initialize).parameters.intersect?([[:keyreq, :params], [:key, :params]])
    def initialize(**options)
      super(**options.merge(params: {}))
    end
  else
    raise 'Grape::Router::Pattern#initialize no longer takes a `params:` keyword. Re-check ' \
      'how declared param types reach Mustermann before upgrading Grape'
  end
end

Grape::Router::Pattern.prepend(GrapeRouterPatternPatch)
