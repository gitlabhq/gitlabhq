# rubocop:disable Naming/FileName
# frozen_string_literal: true

# Sidekiq-cluster code is loaded both inside a Rails/Rspec
# context as well as outside of it via CLI invocation. When it
# is loaded outside of a Rails/Rspec context we do not have access
# to all necessary constants. For example, we need Rails.root to
# determine the location of bin/metrics-server.
# Here we make the necessary constants available conditionally.
require_relative 'override_rails_constants' unless Object.const_defined?('Rails')

require_relative '../config/settings'

# rubocop:enable Naming/FileName
