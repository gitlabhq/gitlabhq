# frozen_string_literal: true

# Configuration used by coverband gem when "COVERBAND_ENABLED" is set to "true"
return unless Gitlab::Utils.to_boolean(ENV['COVERBAND_ENABLED'], default: false)

# Set coverband config file name so it is not started with default configuration
ENV["COVERBAND_CONFIG"] = Rails.root.join("config/coverband.rb").to_s

require 'coverband'

# Normally with a Rails Web app Coverband defines a Railtie, which
# is responsible for inserting a middleware that launches a background
# thread. However, since we dynamically require Coverband in this file,
# it is too late for Railties to be defined now so we need to manually
# start the background threads. In addition, each Puma process needs
# its own background thread to report which code paths were hit.
Gitlab::Cluster::LifecycleEvents.on_worker_start do
  ::Coverband::Background.start
end
