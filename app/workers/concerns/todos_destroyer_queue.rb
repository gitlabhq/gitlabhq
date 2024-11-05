# frozen_string_literal: true

##
# Concern for setting Sidekiq settings for the various Todos Destroyers.
#
module TodosDestroyerQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :todos_destroyer
    feature_category :notifications
  end
end
