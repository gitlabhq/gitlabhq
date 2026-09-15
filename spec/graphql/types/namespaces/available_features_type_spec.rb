# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::AvailableFeaturesType, feature_category: :shared do
  include GraphqlHelpers

  it_behaves_like 'expose all available feature fields for the namespace'
end
