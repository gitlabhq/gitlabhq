# frozen_string_literal: true

require_relative '../../tooling/danger/multiversion'

module Danger
  class Multiversion < ::Danger::Plugin
    include Tooling::Danger::Multiversion
  end
end
