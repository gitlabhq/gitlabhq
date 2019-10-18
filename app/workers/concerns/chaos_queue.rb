# frozen_string_literal: true
#
module ChaosQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :chaos
    feature_category :chaos_engineering
  end
end
