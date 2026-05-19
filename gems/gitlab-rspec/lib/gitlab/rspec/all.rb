# frozen_string_literal: true

require 'gitlab_quality/test_tooling'

require_relative "../rspec"
require_relative "stub_env"
require_relative "next_instance_of"
require_relative "next_found_instance_of"
require_relative "stub_rails"
require_relative "let_it_be"

require_relative "configurations/time_travel"

Gitlab::Rspec::Configurations::TimeTravel.configure!
