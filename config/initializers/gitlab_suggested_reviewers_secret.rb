# frozen_string_literal: true

return unless Gitlab::Runtime.application? && Gitlab.com? && Gitlab.ee?

Gitlab::AppliedMl::SuggestedReviewers.ensure_secret!
