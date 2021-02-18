# frozen_string_literal: true

require_relative '../../tooling/danger/roulette'

module Danger
  class Roulette < Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Roulette
  end
end
