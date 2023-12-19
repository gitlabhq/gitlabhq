# frozen_string_literal: true

require_relative '../../tooling/danger/outdated_todo'

module Danger
  class Todos < ::Danger::Plugin
    def check_outdated_todos(filenames)
      Tooling::Danger::OutdatedTodo.new(filenames, context: self, allow_fail: from_lefthook?).check
    end

    def from_lefthook?
      %w[1 true].include?(ENV['FROM_LEFTHOOK'])
    end
  end
end
