# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DependencyProxy::GroupSettings::Update, feature_category: :virtual_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:group_settings) { create(:dependency_proxy_group_setting, group: group) }
  let_it_be(:current_user) { create(:user) }
  let(:params) { { group_path: group.full_path, enabled: false } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_dependency_proxy) }

  describe '#resolve' do
    subject { described_class.new(object: group, context: query_context, field: nil).resolve(**params) }

    shared_examples 'updating the dependency proxy group settings' do
      it_behaves_like 'updating the dependency proxy group settings attributes',
        from: { enabled: true },
        to: { enabled: false }

      it 'returns the dependency proxy settings no errors' do
        expect(subject).to eq(
          dependency_proxy_setting: group_settings,
          errors: []
        )
      end
    end

    shared_examples 'denying access to dependency proxy group settings' do
      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    where(:user_role, :shared_examples_name) do
      :owner      | 'updating the dependency proxy group settings'
      :maintainer | 'denying access to dependency proxy group settings'
      :developer  | 'denying access to dependency proxy group settings'
      :reporter   | 'denying access to dependency proxy group settings'
      :guest      | 'denying access to dependency proxy group settings'
      :anonymous  | 'denying access to dependency proxy group settings'
    end

    with_them do
      before do
        stub_config(dependency_proxy: { enabled: true })
        group.send("add_#{user_role}", current_user) unless user_role == :anonymous
      end

      it_behaves_like params[:shared_examples_name]
    end
  end
end
