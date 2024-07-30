# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Users::SetNamespaceCommitEmail, feature_category: :user_profile do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:group) { create(:group, :private) }
  let(:email) { create(:email, user: current_user) }
  let(:input) { {} }
  let(:namespace_id) { group.to_global_id }
  let(:email_id) { email.to_global_id }

  shared_examples 'success' do
    it 'creates namespace commit email with correct values' do
      expect(resolve_mutation[:namespace_commit_email])
        .to have_attributes({ namespace_id: namespace_id.model_id.to_i, email_id: email_id.model_id.to_i })
    end
  end

  describe '#resolve' do
    subject(:resolve_mutation) do
      described_class.new(object: nil, context: query_context, field: nil).resolve(
        namespace_id: namespace_id,
        email_id: email_id
      )
    end

    context 'when current_user does not have permission' do
      it 'raises an error' do
        expect { resolve_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          .with_message(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end

    context 'when the user has permission' do
      before do
        group.add_reporter(current_user)
      end

      context 'when the email does not belong to the target user' do
        let(:email_id) { create(:email).to_global_id }

        it 'returns the validation error' do
          expect(resolve_mutation[:errors]).to contain_exactly("Email must be provided.")
        end
      end

      context 'when namespace is a group' do
        it_behaves_like 'success'
      end

      context 'when namespace is a user' do
        let(:namespace_id) { current_user.namespace.to_global_id }

        it_behaves_like 'success'
      end

      context 'when namespace is a project' do
        let_it_be(:project) { create(:project) }

        let(:namespace_id) { project.project_namespace.to_global_id }

        before do
          project.add_reporter(current_user)
        end

        it_behaves_like 'success'
      end
    end
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_namespace) }
end
