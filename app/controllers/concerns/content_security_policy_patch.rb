# frozen_string_literal: true

##
# `content_security_policy_with_context` makes the caller's context available to the invoked block,
# as this is currently not accessible from `content_security_policy`
#
# This patch is available in content_security_policy starting with Rails 7.2.
# Refs: https://github.com/rails/rails/pull/45115.
module ContentSecurityPolicyPatch
  def content_security_policy_with_context(enabled = true, **options, &block)
    if Rails.gem_version >= Gem::Version.new("7.2")
      ActiveSupport::Deprecation.warn(
        "content_security_policy_with_context should only be used with Rails < 7.2.
        Use content_security_policy instead.")
    end

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
