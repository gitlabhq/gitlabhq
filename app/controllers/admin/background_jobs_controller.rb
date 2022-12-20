# frozen_string_literal: true

module Admin
  class BackgroundJobsController < ApplicationController
    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
  end
end
