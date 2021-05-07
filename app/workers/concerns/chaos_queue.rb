# frozen_string_literal: true
#
module ChaosQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :chaos
    feature_category_not_owned!
    tags :exclude_from_gitlab_com
  end
end
