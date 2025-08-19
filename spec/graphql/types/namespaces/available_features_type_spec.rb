# frozen_string_literal: true

require "spec_helper"

RSpec.describe Types::Namespaces::AvailableFeaturesType, feature_category: :shared do
  include GraphqlHelpers

  let_it_be(:user) { build_stubbed(:user) }

  shared_examples "a type that resolves available features" do
    context 'when the issue_date_filter feature flag is enabled' do
      before do
        stub_feature_flags(issue_date_filter: true)
      end

      it 'returns true' do
        expect(resolve_field(:has_issue_date_filter_feature, namespace, current_user: user)).to be(true)
      end
    end

    context 'when the issue_date_filter feature flag is disabled' do
      before do
        stub_feature_flags(issue_date_filter: false)
      end

      it 'returns false' do
        expect(resolve_field(:has_issue_date_filter_feature, namespace, current_user: user)).to be(false)
      end
    end
  end

  context 'with a group namespace' do
    it_behaves_like 'a type that resolves available features' do
      let_it_be(:namespace) { create(:group) }
    end
  end

  context 'with a project namespace' do
    it_behaves_like 'a type that resolves available features' do
      let_it_be(:namespace) { create(:project_namespace) }
    end
  end

  context 'with a user namespace' do
    it_behaves_like 'a type that resolves available features' do
      let_it_be(:namespace) { create(:user_namespace) }
    end
  end

  it_behaves_like 'expose all available feature fields for the namespace'
end
