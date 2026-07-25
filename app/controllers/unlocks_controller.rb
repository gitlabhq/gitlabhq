# frozen_string_literal: true

# Requesting unlock instructions (#create) must remain available even when the
# organization is read-only, otherwise a locked-out user cannot regain access
# to sign in and read it. The controller's only other actions (#new, #show)
# are reads, which enforcement never blocks.
# See https://gitlab.com/gitlab-org/gitlab/-/work_items/602813
class UnlocksController < Devise::UnlocksController # rubocop:disable Gitlab/NamespacedClass -- Devise controllers are top-level, like ConfirmationsController
  skip_before_action :enforce_read_only_organization

  feature_category :system_access
end
