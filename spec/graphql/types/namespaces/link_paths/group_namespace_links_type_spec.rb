# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths::GroupNamespaceLinksType, feature_category: :shared do
  it_behaves_like 'expose all link paths fields for the namespace'
end
