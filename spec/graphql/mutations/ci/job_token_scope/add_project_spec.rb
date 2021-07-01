# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::AddProject do
  let(:mutation) do
    described_class.new(object: nil, context: { current_user: current_user }, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:target_project) { create(:project) }

    let(:target_project_path) { target_project.full_path }

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

        it 'adds target project to the job token scope' do
          expect do
            expect(subject).to include(ci_job_token_scope: be_present, errors: be_empty)
          end.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
        end

        context 'when the service returns an error' do
          let(:service) { double(:service) }

          it 'returns an error response' do
            expect(::Ci::JobTokenScope::AddProjectService).to receive(:new).with(project, current_user).and_return(service)
            expect(service).to receive(:execute).with(target_project).and_return(ServiceResponse.error(message: 'The error message'))

            expect(subject.fetch(:ci_job_token_scope)).to be_nil
            expect(subject.fetch(:errors)).to include("The error message")
          end
        end
      end
    end
  end
end
