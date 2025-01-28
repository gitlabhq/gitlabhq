# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::ClearAllowlistAutopopulations, feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let(:mutation_args) { { project_path: project.full_path } }

    subject(:resolver) do
      mutation.resolve(**mutation_args)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'raises error' do
        expect { resolver }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is logged in' do
      let_it_be(:current_user) { create(:user) }

      context 'when user does not have permissions to admin the project' do
        it 'raises error' do
          expect { resolver }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has permissions to admin the project' do
        before_all do
          project.add_maintainer(current_user)
        end

        context 'when group scope links have been autopopulated' do
          before do
            create(:ci_job_token_group_scope_link, source_project: project, autopopulated: true)
            create(:ci_job_token_group_scope_link, source_project: project, autopopulated: false)
          end

          it 'removes the autopopulated group links' do
            expect do
              expect(resolver).to include(errors: be_empty)
            end.to change { Ci::JobToken::GroupScopeLink.autopopulated.count }.by(-1)
              .and not_change { Ci::JobToken::ProjectScopeLink.autopopulated.count }
          end
        end

        context 'when project scope links have been autopopulated' do
          before do
            create(:ci_job_token_project_scope_link, source_project: project, direction: :inbound,
              autopopulated: true)
            create(:ci_job_token_project_scope_link, source_project: project, direction: :inbound,
              autopopulated: false)
          end

          it 'removes the autopopulated project links' do
            expect do
              expect(resolver).to include(errors: be_empty)
            end.to change { Ci::JobToken::ProjectScopeLink.autopopulated.count }.by(-1)
              .and not_change { Ci::JobToken::GroupScopeLink.autopopulated.count }
          end
        end

        context 'when the service returns an error' do
          let(:service) { instance_double(::Ci::JobToken::ClearAutopopulatedAllowlistService) }

          it 'returns an error response' do
            expect(::Ci::JobToken::ClearAutopopulatedAllowlistService).to receive(:new).with(project,
              current_user).and_return(service)
            expect(service).to receive(:execute)
              .and_return(ServiceResponse.error(message: 'The error message'))

            expect(resolver.fetch(:errors)).to include("The error message")
          end
        end
      end
    end
  end
end
