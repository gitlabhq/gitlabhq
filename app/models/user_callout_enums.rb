# frozen_string_literal: true

module UserCalloutEnums
  # Returns the `Hash` to use for the `feature_name` enum in the `UserCallout`
  # model.
  #
  # This method is separate from the `UserCallout` model so that it can be
  # extended by EE.
  def self.feature_names
    {
      gke_cluster_integration: 1,
      gcp_signup_offer: 2,
      cluster_security_warning: 3,
      suggest_popover_dismissed: 4
    }
  end
end
