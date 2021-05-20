# frozen_string_literal: true

require_relative '../../tooling/danger/product_intelligence'

module Danger
  class ProductIntelligence < ::Danger::Plugin
    # Put the helper code somewhere it can be tested
    include Tooling::Danger::ProductIntelligence
  end
end
