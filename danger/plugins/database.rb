# frozen_string_literal: true

require_relative '../../tooling/danger/database'

module Danger
  class Database < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Database
  end
end
