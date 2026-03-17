# frozen_string_literal: true

require_relative '../../tooling/danger/database'
require_relative '../../tooling/danger/prevent_index_creation_suggestion'

module Danger
  class Database < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Database
  end
end
