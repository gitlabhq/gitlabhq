# frozen_string_literal: true

# Cronjobs that call other cronjobs should have their own tag
# so that we can isolate cron activity to make end-to-end code
# mappings better.
module CronjobChildWorker # rubocop:disable Gitlab/BoundedContexts -- it's a general purpose module
  extend ActiveSupport::Concern

  included do
    tags :cronjob_child
  end
end
