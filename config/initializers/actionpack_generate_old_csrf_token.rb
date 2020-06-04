# frozen_string_literal: true

module Gitlab
  module RequestForgeryProtectionPatch
    private

    # Patch to generate 6.0.3 tokens so that we do not have CSRF errors while
    # rolling out 6.0.3.1. This enables GitLab to have a mix of 6.0.3 and
    # 6.0.3.1 Rails servers
    #
    # 1. Deploy this patch with :global_csrf_token FF disabled.
    # 2. Once all Rails servers are on 6.0.3.1, enable :global_csrf_token FF.
    # 3. On GitLab 13.2, remove this patch
    def masked_authenticity_token(session, form_options: {})
      action, method = form_options.values_at(:action, :method)

      raw_token = if per_form_csrf_tokens && action && method
                    action_path = normalize_action_path(action)
                    per_form_csrf_token(session, action_path, method)
                  else
                    if Feature.enabled?(:global_csrf_token)
                      global_csrf_token(session)
                    else
                      real_csrf_token(session)
                    end
                  end

      mask_token(raw_token)
    end
  end
end

ActionController::Base.include Gitlab::RequestForgeryProtectionPatch
