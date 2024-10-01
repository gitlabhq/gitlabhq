# frozen_string_literal: true

# Configuration used by coverband gem when "COVERBAND_ENABLED" is set to "true"
return unless Gitlab::Utils.to_boolean(ENV['COVERBAND_ENABLED'], default: false)

# Set coverband config file name so it is not started with default configuration
ENV["COVERBAND_CONFIG"] = Rails.root.join("config/coverband.rb").to_s

require 'coverband'
