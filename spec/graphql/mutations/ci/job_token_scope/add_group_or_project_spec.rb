# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::AddGroupOrProject, feature_category: :continuous_integration do
  include GraphqlHelpers

  let(:mutation) do
    described_class.new(object: nil, context: query_context, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) do
      create(:project, ci_inbound_job_token_scope_enabled: true).tap(&:save!)
    end

    subject(:resolver) do
      mutation.resolve(**mutation_args)
    end

    shared_examples 'when user is not logged in' do
      let(:current_user) { nil }

      it 'raises error' do
        expect { resolver }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    shared_examples 'when user does not have permissions to admin project' do
      it 'raises error' do
        expect { resolver }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when we add a project' do
      let_it_be(:target_project) { create(:project) }
      let_it_be(:target_project_path) { target_project.full_path }

      let(:policies) { %w[read_containers read_packages] }

      let(:mutation_args) do
        {
          project_path: project.full_path,
          target_path: target_project_path,
          default_permissions: false,
          job_token_policies: policies
        }
      end

      it_behaves_like 'when user is not logged in'

      context 'when user is logged in' do
        let_it_be(:current_user) { create(:user) }

        it_behaves_like 'when user does not have permissions to admin project'

        context 'when user has permissions to admin project and read target project' do
          before_all do
            project.add_maintainer(current_user)
            target_project.add_guest(current_user)
          end

          it 'adds target project to the inbound job token scope by default' do
            expect { resolver }.to change { Ci::JobToken::ProjectScopeLink.count }.by(1)
            expect(resolver).to include(ci_job_token_scope: be_present, errors: be_empty)

            project_link = Ci::JobToken::ProjectScopeLink.last

            expect(project_link.source_project).to eq(project)
            expect(project_link.target_project).to eq(target_project)
            expect(project_link.added_by).to eq(current_user)
            expect(project_link.default_permissions).to be(false)
            expect(project_link.job_token_policies).to eq(policies)
          end

          context 'when the policies provided are invalid' do
            let(:policies) { %w[read_issue read_project] }

            it 'returns an error message' do
              expect(resolver.fetch(:errors))
              .to include('Validation failed: Job token policies must be a valid json schema')
            end
          end
        end

        context 'when user has no permissions to read target project' do
          before_all do
            project.add_maintainer(current_user)
          end

          it 'returns an error message' do
            response = resolver

            expect(response.fetch(:errors))
            .to include(Ci::JobTokenScope::EditScopeValidations::TARGET_PROJECT_UNAUTHORIZED_OR_UNFOUND)
          end
        end
      end
    end

    context 'when we add a group' do
      let_it_be(:target_group) { create(:group, :private) }
      let_it_be(:target_group_path) { target_group.full_path }

      let(:policies) { %w[read_containers read_packages] }

      let(:mutation_args) do
        {
          project_path: project.full_path,
          target_path: target_group_path,
          default_permissions: false,
          job_token_policies: policies
        }
      end

      it_behaves_like 'when user is not logged in'

      context 'when user is logged in' do
        let_it_be(:current_user) { create(:user) }

        it_behaves_like 'when user does not have permissions to admin project'

        context 'when user has permissions to admin project and read target group' do
          before_all do
            project.add_maintainer(current_user)
            target_group.add_guest(current_user)
          end

          it 'adds target group to the job token scope' do
            expect { resolver }.to change { Ci::JobToken::GroupScopeLink.count }.by(1)
            expect(resolver).to include(ci_job_token_scope: be_present, errors: be_empty)

            group_link = Ci::JobToken::GroupScopeLink.last

            expect(group_link.source_project).to eq(project)
            expect(group_link.target_group).to eq(target_group)
            expect(group_link.added_by).to eq(current_user)
            expect(group_link.default_permissions).to be(false)
            expect(group_link.job_token_policies).to eq(policies)
          end

          context 'when the policies provided are invalid' do
            let(:policies) { %w[read_issue read_project] }

            it 'returns an error message' do
              response = resolver

              expect(response.fetch(:errors))
              .to include('Validation failed: Job token policies must be a valid json schema')
            end
          end
        end

        context 'when user has no permissions to admin project' do
          before_all do
            target_group.add_guest(current_user)
          end

          it 'raises an error' do
            expect do
              resolver
            end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when user has no permissions to read target group' do
          before_all do
            project.add_maintainer(current_user)
          end

          it 'returns an error message' do
            response = resolver

            expect(response.fetch(:errors))
            .to include(::Ci::JobTokenScope::EditScopeValidations::TARGET_GROUP_UNAUTHORIZED_OR_UNFOUND)
          end
        end
      end
    end
  end
end
