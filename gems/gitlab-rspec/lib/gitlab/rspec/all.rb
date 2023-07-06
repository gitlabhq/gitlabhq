# frozen_string_literal: true

require_relative "../rspec"
require_relative "stub_env"

require_relative "configurations/time_travel"

Gitlab::Rspec::Configurations::TimeTravel.configure!
