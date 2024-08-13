# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Groups::Update, feature_category: :api do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:params) { { full_path: group.full_path } }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_group_or_admin_runner) }

  describe '#resolve' do
    subject { described_class.new(object: group, context: context, field: nil).resolve(**params) }

    shared_examples 'updating the group shared runners setting' do
      it 'updates the group shared runners setting' do
        expect { subject }
          .to change { group.reload.shared_runners_setting }.from('enabled').to(Namespace::SR_DISABLED_AND_UNOVERRIDABLE)
      end

      it 'returns no errors' do
        expect(subject).to eq(errors: [], group: group)
      end

      context 'with invalid params' do
        let_it_be(:params) { { full_path: group.full_path, shared_runners_setting: 'inexistent_setting' } }

        it 'doesn\'t update the shared_runners_setting' do
          expect { subject }
            .not_to change { group.reload.shared_runners_setting }
        end

        it 'returns an error' do
          expect(subject).to eq(
            group: nil,
            errors: ["Update shared runners state must be one of: #{::Namespace::SHARED_RUNNERS_SETTINGS.join(', ')}"]
          )
        end
      end
    end

    shared_examples 'updating the group math rendering settings' do
      it 'updates the settings' do
        expect { subject }
          .to change { group.reload.math_rendering_limits_enabled? }.to(false)
          .and change { group.reload.lock_math_rendering_limits_enabled? }.to(true)
      end

      it 'returns no errors' do
        expect(subject).to eq(errors: [], group: group)
      end
    end

    shared_examples 'denying access to group' do
      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'changing shared runners setting' do
      let_it_be(:params) do
        { full_path: group.full_path,
          shared_runners_setting: Namespace::SR_DISABLED_AND_UNOVERRIDABLE }
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the group shared runners setting'
        :maintainer | 'denying access to group'
        :developer  | 'denying access to group'
        :reporter   | 'denying access to group'
        :guest      | 'denying access to group'
        :anonymous  | 'denying access to group'
      end

      with_them do
        before do
          group.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'changing math rendering settings' do
      let_it_be(:params) do
        {
          full_path: group.full_path,
          math_rendering_limits_enabled: false,
          lock_math_rendering_limits_enabled: true
        }
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the group math rendering settings'
        :maintainer | 'denying access to group'
        :developer  | 'denying access to group'
        :reporter   | 'denying access to group'
        :guest      | 'denying access to group'
        :anonymous  | 'denying access to group'
      end

      with_them do
        before do
          group.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
