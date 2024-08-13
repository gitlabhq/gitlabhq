# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DependencyProxy::ImageTtlGroupPolicy::Update, feature_category: :virtual_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  let(:params) { { group_path: group.full_path } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_dependency_proxy) }

  describe '#resolve' do
    subject { described_class.new(object: group, context: query_context, field: nil).resolve(**params) }

    shared_examples 'returning a success' do
      it 'returns the dependency proxy image ttl group policy with no errors' do
        expect(subject).to eq(
          dependency_proxy_image_ttl_policy: ttl_policy,
          errors: []
        )
      end
    end

    shared_examples 'updating the dependency proxy image ttl policy' do
      it_behaves_like 'updating the dependency proxy image ttl policy attributes',
        from: { enabled: true, ttl: 90 },
        to: { enabled: false, ttl: 2 }

      it_behaves_like 'returning a success'

      context 'with invalid params' do
        let_it_be(:params) { { group_path: group.full_path, enabled: nil } }

        it "doesn't create the dependency proxy image ttl policy" do
          expect { subject }.not_to change { DependencyProxy::ImageTtlGroupPolicy.count }
        end

        it 'does not update' do
          expect { subject }
            .not_to change { ttl_policy.reload.enabled }
        end

        it 'returns an error' do
          expect(subject).to eq(
            dependency_proxy_image_ttl_policy: nil,
            errors: ['Enabled is not included in the list']
          )
        end
      end
    end

    shared_examples 'denying access to dependency proxy image ttl policy' do
      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    before do
      stub_config(dependency_proxy: { enabled: true })
    end

    context 'with existing dependency proxy image ttl policy' do
      let_it_be(:ttl_policy) { create(:image_ttl_group_policy, group: group) }
      let_it_be(:params) do
        { group_path: group.full_path,
          enabled: false,
          ttl: 2 }
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the dependency proxy image ttl policy'
        :maintainer | 'denying access to dependency proxy image ttl policy'
        :developer  | 'denying access to dependency proxy image ttl policy'
        :reporter   | 'denying access to dependency proxy image ttl policy'
        :guest      | 'denying access to dependency proxy image ttl policy'
        :anonymous  | 'denying access to dependency proxy image ttl policy'
      end

      with_them do
        before do
          group.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing dependency proxy image ttl policy' do
      let_it_be(:ttl_policy) { group.dependency_proxy_image_ttl_policy }

      where(:user_role, :shared_examples_name) do
        :owner      | 'creating the dependency proxy image ttl policy'
        :maintainer | 'denying access to dependency proxy image ttl policy'
        :developer  | 'denying access to dependency proxy image ttl policy'
        :reporter   | 'denying access to dependency proxy image ttl policy'
        :guest      | 'denying access to dependency proxy image ttl policy'
        :anonymous  | 'denying access to dependency proxy image ttl policy'
      end

      with_them do
        before do
          group.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
