# frozen_string_literal: true

require_relative '../../tooling/danger/outdated_todo'

module Danger
  class Todos < ::Danger::Plugin
    def check_outdated_todos(filenames)
      Tooling::Danger::OutdatedTodo.new(filenames, context: self).check
    end
  end
end
