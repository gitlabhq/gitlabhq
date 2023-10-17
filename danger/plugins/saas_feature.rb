# frozen_string_literal: true

require_relative '../../tooling/danger/saas_feature'

module Danger
  class SaasFeature < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::SaasFeature
  end
end
