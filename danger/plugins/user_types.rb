# frozen_string_literal: true

require_relative '../../tooling/danger/user_types'

module Danger
  class UserTypes < ::Danger::Plugin
    include Tooling::Danger::UserTypes
  end
end
