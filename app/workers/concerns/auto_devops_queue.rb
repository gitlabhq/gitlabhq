# frozen_string_literal: true

module AutoDevopsQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :auto_devops
    feature_category :auto_devops
  end
end
