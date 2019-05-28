# frozen_string_literal: true

require 'net/http'
require 'yaml'

require_relative '../../lib/gitlab/danger/helper'

module Danger
  # Common helper functions for our danger scripts. See Gitlab::Danger::Helper
  # for more details
  class Helper < Plugin
    # Put the helper code somewhere it can be tested
    include Gitlab::Danger::Helper
  end
end
