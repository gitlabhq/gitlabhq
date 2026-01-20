# frozen_string_literal: true

require_relative '../../tooling/danger/index_removal'

module Danger
  class IndexRemoval < ::Danger::Plugin
    def add_suggestions_for(filename)
      Tooling::Danger::IndexRemoval.new(filename, context: self).suggest
    end
  end
end
