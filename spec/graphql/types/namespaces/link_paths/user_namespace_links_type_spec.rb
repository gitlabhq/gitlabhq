# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::LinkPaths::UserNamespaceLinksType, feature_category: :shared do
  it_behaves_like 'expose all link paths fields for the namespace'

  context "when fetching user namespace" do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { user.namespace }

    it_behaves_like "common namespace link paths values"
  end
end
