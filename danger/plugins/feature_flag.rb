# frozen_string_literal: true

require_relative '../../tooling/danger/feature_flag'

module Danger
  class FeatureFlag < Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::FeatureFlag
  end
end
