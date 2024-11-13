# frozen_string_literal: true

class SandboxController < ApplicationController # rubocop:disable Gitlab/NamespacedClass
  skip_before_action :authenticate_user!
  skip_before_action :enforce_terms!
  skip_before_action :check_two_factor_requirement

  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  def mermaid
    render layout: false
  end

  def swagger
    render layout: false
  end
end
