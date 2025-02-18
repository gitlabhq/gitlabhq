# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::AutopopulateAllowlist, feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:origin_project) { create(:project) }
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

          create(:ci_job_token_authorization, origin_project: origin_project, accessed_project: project,
            last_authorized_at: 1.day.ago)
        end

        it 'adds target project to the inbound job token scope by default' do
          expect do
            expect(resolver).to include(errors: be_empty)
          end.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
        end

        context 'when the clear service returns an error' do
          let(:service) { instance_double(::Ci::JobToken::ClearAutopopulatedAllowlistService) }

          it 'returns an error response' do
            expect(::Ci::JobToken::ClearAutopopulatedAllowlistService).to receive(:new).with(project,
              current_user).and_return(service)
            expect(service).to receive(:execute)
              .and_return(ServiceResponse.error(message: 'Clear service error message'))

            expect(resolver.fetch(:errors)).to include("Clear service error message")
          end
        end

        context 'when the autopopulate service returns an error' do
          let(:service) { instance_double(::Ci::JobToken::AutopopulateAllowlistService) }

          it 'returns an error response' do
            expect(::Ci::JobToken::AutopopulateAllowlistService).to receive(:new).with(project,
              current_user).and_return(service)
            expect(service).to receive(:execute)
              .and_return(ServiceResponse.error(message: 'Autopopulates service error message'))

            expect(resolver.fetch(:errors)).to include("Autopopulates service error message")
          end
        end
      end
    end
  end
end
