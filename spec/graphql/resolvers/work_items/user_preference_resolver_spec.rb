# frozen_string_literal: true

require "spec_helper"

RSpec.describe Resolvers::WorkItems::UserPreferenceResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:work_item_type) { WorkItems::Type.default_by_type(:issue) }

  let(:args) do
    {
      namespace_path: namespace.full_path,
      work_item_type_id: work_item_type&.to_gid
    }
  end

  let(:result) do
    resolve(
      described_class,
      obj: current_user,
      args: args,
      ctx: {
        current_user: current_user
      }
    )
  end

  shared_examples 'resolve work items user preferences' do
    context 'when user does not have access to the namespace' do
      it 'does not update the user preference and return access error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          result
        end
      end
    end

    context 'when user have access to the namespace' do
      before_all do
        namespace.add_guest(current_user)
      end

      context 'when a user preference is not found' do
        let_it_be(:work_item_type) { nil }

        it 'returns nil when the user preference is not found' do
          expect(result).to be_blank
        end
      end

      context 'when a user preference is found' do
        it 'returns the user preference when it is found' do
          expect(result).to eq(user_preference)
        end
      end
    end
  end

  context 'when namespace is a group' do
    let_it_be(:namespace) { create(:group, :private) }

    let_it_be(:user_preference) do
      create(
        :work_item_user_preference,
        namespace: namespace,
        work_item_type: work_item_type,
        user: current_user
      )
    end

    it_behaves_like 'resolve work items user preferences'
  end

  context 'when namespace is a project' do
    let_it_be(:namespace) { create(:project, :private) }

    let_it_be(:user_preference) do
      create(
        :work_item_user_preference,
        namespace: namespace.project_namespace,
        work_item_type: work_item_type,
        user: current_user
      )
    end

    it_behaves_like 'resolve work items user preferences'
  end
end
