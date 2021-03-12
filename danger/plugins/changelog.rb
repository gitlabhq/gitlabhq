# frozen_string_literal: true

require_relative '../../tooling/danger/changelog'

module Danger
  class Changelog < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Changelog
  end
end
