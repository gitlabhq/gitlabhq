# frozen_string_literal: true

module UserCalloutEnums
  # Returns the `Hash` to use for the `feature_name` enum in the `UserCallout`
  # model.
  #
  # This method is separate from the `UserCallout` model so that it can be
  # extended by EE.
  #
  # If you are going to add new items to this hash, check that you're not going
  # to conflict with EE-only values: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/ee/app/models/ee/user_callout_enums.rb
  def self.feature_names
    {
      gke_cluster_integration: 1,
      gcp_signup_offer: 2,
      cluster_security_warning: 3,
      suggest_popover_dismissed: 9,
      privacy_policy_update_64341: 10 # Privacy Policy Update: https://gitlab.com/gitlab-org/gitlab-ce/issues/64341
    }
  end
end
