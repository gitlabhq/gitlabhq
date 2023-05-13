# frozen_string_literal: true

require_relative '../../tooling/danger/analytics_instrumentation'

module Danger
  class AnalyticsInstrumentation < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::AnalyticsInstrumentation
  end
end
