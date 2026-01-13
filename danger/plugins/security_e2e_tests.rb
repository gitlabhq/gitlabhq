# frozen_string_literal: true

require_relative '../../tooling/danger/security_e2e_tests'

module Danger
  class SecurityE2eTests < ::Danger::Plugin
    include Tooling::Danger::SecurityE2eTests
  end
end
