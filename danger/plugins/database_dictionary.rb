# frozen_string_literal: true

require_relative '../../tooling/danger/database_dictionary'

module Danger
  class DatabaseDictionary < Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::DatabaseDictionary
  end
end
