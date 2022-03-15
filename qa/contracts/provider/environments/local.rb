# frozen_string_literal: true

module Provider
  module Environments
    class Local < Base
      def initialize
        @base_url = ENV['CONTRACT_HOST']
        @merge_request = ENV['CONTRACT_MR']
      end
    end
  end
end
