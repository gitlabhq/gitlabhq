# frozen_string_literal: true

# TEMPORARY PATCH - REMOVE AFTER RAILS 7.2 MIGRATION IS COMPLETE
#
# This patch provides backwards compatibility for content_security_policy_with_context
# during the Rails 7.2 upgrade process.
#
# TODO: Remove this entire file once all controllers have been updated to use
# the native content_security_policy method instead of content_security_policy_with_context.
#
# Migration steps:
# 1. Update all controllers to use content_security_policy instead of content_security_policy_with_context
# 2. Remove this file

module ContentSecurityPolicyPatch
  def content_security_policy_with_context(enabled = true, **options, &block)
    if Rails.gem_version >= Gem::Version.new("7.2")
      # For Rails 7.2+, redirect to the native implementation
      content_security_policy(enabled, **options, &block)
    else
      # Original patch implementation for Rails < 7.2
      before_action(options) do
        if block
          policy = current_content_security_policy
          instance_exec(policy, &block)
          request.content_security_policy = policy
        end

        request.content_security_policy = nil unless enabled
      end
    end
  end
end
