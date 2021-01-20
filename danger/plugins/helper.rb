# frozen_string_literal: true

require_relative '../../tooling/danger/helper'

module Danger
  # Common helper functions for our danger scripts. See Tooling::Danger::Helper
  # for more details
  class Helper < Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::Helper
  end
end
