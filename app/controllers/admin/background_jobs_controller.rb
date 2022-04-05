# frozen_string_literal: true

class Admin::BackgroundJobsController < Admin::ApplicationController
  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned
end
