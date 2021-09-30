# frozen_string_literal: true

require 'fogbugz'

module Gitlab
  module FogbugzImport
    # Custom adapter to validate the URL before each request
    # This way we avoid DNS rebinds or other unsafe requests
    ::Fogbugz.adapter[:http] = HttpAdapter
  end
end
