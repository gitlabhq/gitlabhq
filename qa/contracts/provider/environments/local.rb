# frozen_string_literal: true

require_relative './base'

module Environments
  class Local < Base
    def initialize
      @base_url = ENV['CONTRACT_HOST']
      @merge_request = ENV['CONTRACT_MR']
    end
  end
end
