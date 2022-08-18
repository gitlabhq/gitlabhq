# frozen_string_literal: true

require_relative '../../tooling/danger/customer_success'

module Danger
  class CustomerSuccess < ::Danger::Plugin
    include Tooling::Danger::CustomerSuccess
  end
end
