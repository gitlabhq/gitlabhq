# frozen_string_literal: true

class CombinedRegistrationExperiment < ApplicationExperiment
  include Rails.application.routes.url_helpers

  def key_for(source, _ = nil)
    super(source, 'force_company_trial')
  end

  def redirect_path
    run
  end

  def control_behavior
    new_users_sign_up_group_path
  end

  def candidate_behavior
    new_users_sign_up_groups_project_path
  end
end
