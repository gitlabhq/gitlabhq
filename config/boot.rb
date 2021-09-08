# frozen_string_literal: true

require_relative 'bundler_setup'
require 'bootsnap/setup' if ENV['RAILS_ENV'] != 'production' || %w(1 yes true).include?(ENV['ENABLE_BOOTSNAP'])
