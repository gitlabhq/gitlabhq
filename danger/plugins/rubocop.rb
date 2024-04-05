# frozen_string_literal: true

require_relative '../../tooling/danger/rubocop_discourage_todo_addition'
require_relative '../../tooling/danger/rubocop_inline_disable_suggestion'
require_relative '../../tooling/danger/rubocop_new_todo'
require_relative '../../tooling/danger/rubocop_helper'

module Danger
  class Rubocop < ::Danger::Plugin
    include Tooling::Danger::RubocopHelper
  end
end
