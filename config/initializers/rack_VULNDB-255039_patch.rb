# frozen_string_literal: true

if Gem.loaded_specs['rack'].version >= Gem::Version.new("3.0.0")
  raise <<~ERR
  This patch is unnecessary in Rack versions 3.0.0 or newer.
  Please remove this file and the associated spec.

  See https://github.com/rack/rack/blob/main/CHANGELOG.md#security (issue #1733)
  ERR
end

# Patches a cache poisoning attack vector in Rack by not allowing semicolons
# to delimit query parameters.
# See https://github.com/rack/rack/issues/1732.
#
# Solution is taken from the same issue.
#
# The actual patch is due for release in Rack 3.0.0.
module Rack
  class Request
    Helpers.module_eval do
      # rubocop: disable Naming/MethodName
      def GET
        if get_header(RACK_REQUEST_QUERY_STRING) == query_string
          get_header(RACK_REQUEST_QUERY_HASH)
        else
          query_hash = parse_query(query_string, '&') # only allow ampersand here
          set_header(RACK_REQUEST_QUERY_STRING, query_string)
          set_header(RACK_REQUEST_QUERY_HASH, query_hash)
        end
      end
      # rubocop: enable Naming/MethodName
    end
  end
end
