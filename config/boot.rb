# frozen_string_literal: true

require_relative 'bundler_setup'

enable_bootsnap_default_value = ENV['RAILS_ENV'] != 'production' ? '1' : '0'
require 'bootsnap/setup' if %w[1 yes true].include?(ENV.fetch('ENABLE_BOOTSNAP', enable_bootsnap_default_value))
