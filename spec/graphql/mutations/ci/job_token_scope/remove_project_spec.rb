# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::RemoveProject, feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }
    let_it_be(:target_project) { create(:project) }

    let_it_be(:link) do
      create(:ci_job_token_project_scope_link,
        source_project: project,
        target_project: target_project)
    end

    let(:target_project_path) { target_project.full_path }
    let(:links_relation) { Ci::JobToken::ProjectScopeLink.with_source(project).with_target(target_project) }

    subject do
      mutation.resolve(project_path: project.full_path, target_project_path: target_project_path)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is logged in' do
      let(:current_user) { create(:user) }

      context 'when user does not have permissions to admin project' do
        it 'raises error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has permissions to admin project and read target project' do
        before do
          project.add_maintainer(current_user)
          target_project.add_guest(current_user)
        end

        let(:service) { instance_double('Ci::JobTokenScope::RemoveProjectService') }

        context 'with no direction specified' do
          it 'defaults to asking the RemoveProjectService to remove the outbound link' do
            expect(::Ci::JobTokenScope::RemoveProjectService)
              .to receive(:new).with(project, current_user).and_return(service)
            expect(service).to receive(:execute).with(target_project, :outbound)
              .and_return(instance_double('ServiceResponse', "success?": true, payload: link))

            subject
          end
        end

        context 'with direction specified' do
          subject do
            mutation.resolve(project_path: project.full_path, target_project_path: target_project_path, direction: 'inbound')
          end

          it 'executes project removal for the correct direction' do
            expect(::Ci::JobTokenScope::RemoveProjectService)
              .to receive(:new).with(project, current_user).and_return(service)
            expect(service).to receive(:execute).with(target_project, 'inbound')
              .and_return(instance_double('ServiceResponse', "success?": true, payload: link))

            subject
          end
        end

        context 'when the service returns an error' do
          let(:service) { instance_double('Ci::JobTokenScope::RemoveProjectService') }

          it 'returns an error response' do
            expect(::Ci::JobTokenScope::RemoveProjectService).to receive(:new).with(project, current_user).and_return(service)
            expect(service).to receive(:execute).with(target_project, :outbound).and_return(ServiceResponse.error(message: 'The error message'))

            expect(subject.fetch(:ci_job_token_scope)).to be_nil
            expect(subject.fetch(:errors)).to include("The error message")
          end
        end
      end
    end
  end
end
