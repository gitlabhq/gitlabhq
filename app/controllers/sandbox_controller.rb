# frozen_string_literal: true

class SandboxController < ApplicationController # rubocop:disable Gitlab/NamespacedClass
  skip_before_action :authenticate_user!
  skip_before_action :enforce_terms!
  skip_before_action :check_two_factor_requirement

  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  content_security_policy(only: :mermaid) do |p|
    next if !Gitlab.config.asset_proxy.enabled || !Gitlab.config.asset_proxy.csp_directives

    p.img_src(*Gitlab.config.asset_proxy.csp_directives)
    p.media_src(*Gitlab.config.asset_proxy.csp_directives)
  end

  def mermaid
    render layout: false
  end

  def swagger
    render layout: false
  end
end
