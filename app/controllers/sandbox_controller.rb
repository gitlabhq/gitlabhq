# frozen_string_literal: true

class SandboxController < ApplicationController # rubocop:disable Gitlab/NamespacedClass
  skip_before_action :authenticate_user!

  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  def mermaid
    render layout: false
  end

  def swagger
    render layout: false
  end
end
