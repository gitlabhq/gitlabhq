# frozen_string_literal: true

require_relative '../../tooling/danger/retention_policy_allowlist'

module Danger
  class RetentionPolicyAllowlist < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::RetentionPolicyAllowlist
  end
end
