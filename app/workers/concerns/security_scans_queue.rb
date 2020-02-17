# frozen_string_literal: true

##
# Concern for setting Sidekiq settings for the various Secure product queues
#
module SecurityScansQueue
  extend ActiveSupport::Concern

  included do
    queue_namespace :security_scans
    feature_category :static_application_security_testing
  end
end
