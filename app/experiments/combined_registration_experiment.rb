# frozen_string_literal: true

class CombinedRegistrationExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  include Rails.application.routes.url_helpers

  def key_for(source, _ = nil)
    super(source, 'force_company_trial')
  end

  def redirect_path(trial_params)
    @trial_params = trial_params

    run
  end

  def control_behavior
    new_users_sign_up_group_path(@trial_params)
  end

  def candidate_behavior
    new_users_sign_up_groups_project_path
  end
end
