# frozen_string_literal: true

require_relative '../../tooling/danger/internal_users'

module Danger
  class InternalUsers < Plugin
    include Tooling::Danger::InternalUsers
  end
end
