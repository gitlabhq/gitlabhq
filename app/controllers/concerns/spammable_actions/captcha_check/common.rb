# frozen_string_literal: true

module SpammableActions
  module CaptchaCheck
    module Common
      extend ActiveSupport::Concern

      private

      def with_captcha_check_common(spammable:, captcha_render_lambda:, &block)
        # If the Spammable indicates that CAPTCHA is not necessary (either due to it not being flagged
        # as spam, or if spam/captcha is disabled for some reason), then we will go ahead and
        # yield to the block containing the action's original behavior, then return.
        return yield unless spammable.render_recaptcha?

        # If we got here, we need to render the CAPTCHA instead of yielding to action's original
        # behavior. We will present a CAPTCHA to be solved by executing the lambda which was passed
        # as the `captcha_render_lambda:` argument. This lambda contains either the HTML-specific or
        # JSON-specific behavior to cause the CAPTCHA modal to be rendered.
        Gitlab::Recaptcha.load_configurations!
        captcha_render_lambda.call
      end
    end
  end
end
