# frozen_string_literal: true

require_relative '../../tooling/danger/authz_cop_bypass'

module Danger
  class AuthzCopBypass < ::Danger::Plugin
    include Tooling::Danger::AuthzCopBypass
  end
end
