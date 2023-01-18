# frozen_string_literal: true

return unless Gitlab.com? && Gitlab.ee?

Gitlab::AppliedMl::SuggestedReviewers.ensure_secret!
