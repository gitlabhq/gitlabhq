# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::Runner::Delete, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:runner) { create(:ci_runner) }
  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }

  let(:current_ctx) { { current_user: user } }

  let(:mutation_params) do
    { id: runner.to_global_id }
  end

  specify { expect(described_class).to require_graphql_authorizations(:delete_runner) }

  describe '#resolve' do
    subject do
      sync(resolve(described_class, args: mutation_params, ctx: current_ctx))
    end

    context 'when the user cannot admin the runner' do
      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          subject
        end
      end

      context 'with more than one associated project' do
        let!(:project) { create(:project, creator_id: user.id) }
        let!(:project2) { create(:project, creator_id: user.id) }
        let!(:two_projects_runner) { create(:ci_runner, :project, description: 'Two projects runner', projects: [project, project2]) }

        it 'raises an error' do
          mutation_params[:id] = two_projects_runner.to_global_id

          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
            subject
          end
        end
      end
    end

    context 'when required arguments are missing' do
      let(:mutation_params) { {} }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, "missing keyword: :id")
      end
    end

    context 'when user can delete owned runner' do
      let_it_be(:user) { create(:user) }

      let!(:project) { create(:project, creator_id: user.id) }
      let!(:project_runner) { create(:ci_runner, :project, description: 'Project runner', projects: [project]) }

      before do
        project.add_maintainer(user)
      end

      context 'with one associated project' do
        let(:mutation_params) do
          { id: project_runner.to_global_id }
        end

        it 'deletes runner' do
          expect_next_instance_of(::Ci::Runners::UnregisterRunnerService, project_runner, current_ctx[:current_user]) do |service|
            expect(service).to receive(:execute).once.and_call_original
          end

          expect { subject }.to change { Ci::Runner.count }.by(-1)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'with more than one associated project' do
        let!(:project2) { create(:project, creator_id: user.id) }
        let!(:two_projects_runner) { create(:ci_runner, :project, description: 'Two projects runner', projects: [project, project2]) }

        let(:mutation_params) do
          { id: two_projects_runner.to_global_id }
        end

        context 'with user as admin', :enable_admin_mode do
          let(:current_ctx) { { current_user: admin_user } }

          it 'deletes runner' do
            expect_next_instance_of(::Ci::Runners::UnregisterRunnerService, two_projects_runner, current_ctx[:current_user]) do |service|
              expect(service).to receive(:execute).once.and_call_original
            end

            expect { subject }.to change { Ci::Runner.count }.by(-1)
            expect(subject[:errors]).to be_empty
          end
        end

        context 'with user as project maintainer' do
          let_it_be(:user) { create(:user) }

          before do
            project2.add_maintainer(user)
          end

          it 'raises error' do
            allow_next_instance_of(::Ci::Runners::UnregisterRunnerService) do |service|
              expect(service).not_to receive(:execute)
            end

            expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
              subject
            end
          end
        end
      end
    end

    context 'when admin can delete runner', :enable_admin_mode do
      let(:current_ctx) { { current_user: admin_user } }

      it 'deletes runner' do
        expect_next_instance_of(::Ci::Runners::UnregisterRunnerService, runner, current_ctx[:current_user]) do |service|
          expect(service).to receive(:execute).once.and_call_original
        end

        expect { subject }.to change { Ci::Runner.count }.by(-1)
        expect(subject[:errors]).to be_empty
      end
    end
  end
end
