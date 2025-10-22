# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::Create, feature_category: :api do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:work_item_type) { WorkItems::Type.default_issue_type }

  let(:params) { { title: 'Title', project_path: project.full_path, work_item_type_id: work_item_type.to_gid } }
  let(:restricted_params) { { created_at: 2.days.ago } }
  let(:scope_validator) { instance_double(Gitlab::Auth::ScopeValidator, valid_for?: true) }

  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) do
    GraphQL::Query::Context.new(query: query, values: { current_user: user, scope_validator: scope_validator })
  end

  let(:mutation) { described_class.new(object: nil, context: context, field: nil) }
  let(:created_work_item) { subject[:work_item] }

  specify { expect(described_class).to require_graphql_authorizations(:create_work_item) }

  describe '#resolve' do
    def resolve
      mutation.resolve(**params.merge!(restricted_params))
    end

    subject { resolve }

    context 'when the user can create a work item' do
      context 'when creating a work item as a developer' do
        context 'when trying to create a work item with restricted params' do
          it 'ignores the special params' do
            expect(created_work_item.created_at).not_to be_like_time(restricted_params[:created_at])
          end
        end
      end

      context 'when creating a work item as an owner' do
        let_it_be(:user) { project.first_owner }

        it 'sets the special params' do
          expect(created_work_item.created_at).to be_like_time(restricted_params[:created_at])
        end
      end
    end

    context 'with scope_validator context' do
      let(:context) do
        GraphQL::Query::Context.new(query: query, values: { current_user: user, scope_validator: scope_validator })
      end

      it 'passes scope_validator from context to the CreateService' do
        expect(::WorkItems::CreateService).to receive(:new).with(
          hash_including(params: hash_including(scope_validator: scope_validator))
        ).and_call_original

        mutation.resolve(**params.merge!(restricted_params))
      end
    end
  end
end
