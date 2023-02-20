# frozen_string_literal: true

require 'chemlab/library'

module Slack
  include Chemlab::Library

  self.base_url = 'https://slack.com'
end
