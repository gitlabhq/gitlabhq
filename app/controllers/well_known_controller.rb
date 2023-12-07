# frozen_string_literal: true

# This controller implements /.well-known paths that have no better home.
#
# Other controllers also implement /.well-known/* paths. They can be
# discovered by running `rails routes | grep "well-known"`.
class WellKnownController < ApplicationController # rubocop:disable Gitlab/NamespacedClass -- No relevant product domain exists
  skip_before_action :authenticate_user!, :check_two_factor_requirement
  feature_category :compliance_management, [:security_txt]

  def security_txt
    content = Gitlab::CurrentSettings.current_application_settings.security_txt_content
    if content.present?
      render plain: content
    else
      route_not_found
    end
  end
end
