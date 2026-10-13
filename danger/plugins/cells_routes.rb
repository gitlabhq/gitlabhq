# frozen_string_literal: true

require_relative '../../tooling/danger/cells_routes'

module Danger
  class CellsRoutes < ::Danger::Plugin
    include Tooling::Danger::CellsRoutes
  end
end
