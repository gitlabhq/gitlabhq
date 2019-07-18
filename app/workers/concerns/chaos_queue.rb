# frozen_string_literal: true
#
module ChaosQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :chaos
  end
end
