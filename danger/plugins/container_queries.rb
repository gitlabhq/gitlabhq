# frozen_string_literal: true

require_relative '../../tooling/danger/container_queries'

module Danger
  class ContainerQueries < ::Danger::Plugin
    # Include the helper code
    include Tooling::Danger::ContainerQueries
  end
end
