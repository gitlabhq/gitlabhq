# frozen_string_literal: true

require_relative '../../tooling/danger/documentation'

module Danger
  class Documentation < ::Danger::Plugin
    include Tooling::Danger::Documentation
  end
end
