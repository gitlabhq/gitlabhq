# frozen_string_literal: true

require_relative '../../tooling/danger/clickhouse'

module Danger
  class Clickhouse < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Clickhouse
  end
end
