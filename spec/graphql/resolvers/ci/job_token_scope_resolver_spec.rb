# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::JobTokenScopeResolver, feature_category: :continuous_integration do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, ci_outbound_job_token_scope_enabled: true).tap(&:save!) }

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::JobTokenScopeType)
  end

  subject(:resolve_scope) { resolve(described_class, ctx: { current_user: current_user }, obj: project) }

  describe '#resolve' do
    context 'with access to scope' do
      before do
        project.add_member(current_user, :maintainer)
      end

      it 'returns the same project in the allow list of projects for the Ci Job Token when scope is not enabled' do
        allow(project).to receive(:ci_outbound_job_token_scope_enabled?).and_return(false)

        expect(resolve_scope.outbound_projects).to contain_exactly(project)
      end

      it 'returns the same project in the allow list of projects for the Ci Job Token' do
        expect(resolve_scope.outbound_projects).to contain_exactly(project)
      end

      context 'when another projects gets added to the allow list' do
        let!(:link) { create(:ci_job_token_project_scope_link, source_project: project) }

        it 'returns both projects' do
          expect(resolve_scope.outbound_projects).to contain_exactly(project, link.target_project)
        end
      end

      context 'when job token scope is disabled' do
        before do
          project.update!(ci_outbound_job_token_scope_enabled: false)
        end

        it 'resolves projects' do
          expect(resolve_scope.outbound_projects).to contain_exactly(project)
        end
      end
    end

    context 'when projects list counter is requested' do
      let!(:link) { create(:ci_job_token_project_scope_link, source_project: project) }

      before do
        project.add_member(current_user, :maintainer)
      end

      it 'resolves projects count' do
        expect(resolve_scope.inbound_projects_count).to eq(1)
      end
    end

    context 'when groups list counter is requested' do
      let_it_be(:group) { create(:group, :private) }
      let!(:group_scope_link) { create(:ci_job_token_group_scope_link, source_project: project, target_group: group) }

      before do
        project.add_member(current_user, :maintainer)
      end

      it 'resolves groups count' do
        expect(resolve_scope.groups_count).to eq(1)
      end
    end

    context 'when groups list is requested' do
      let_it_be(:group) { create(:group, :private) }
      let!(:group_scope_link) { create(:ci_job_token_group_scope_link, source_project: project, target_group: group) }

      context 'with access to scope' do
        before do
          project.add_member(current_user, :maintainer)
        end

        it 'resolves groups' do
          expect(resolve_scope.groups).to contain_exactly(group)
        end

        context 'when job token scope is disabled' do
          before do
            project.update!(ci_inbound_job_token_scope_enabled: false)
          end

          it 'resolves groups' do
            expect(resolve_scope.groups).to contain_exactly(group)
          end
        end
      end
    end

    context 'without access to scope' do
      before do
        project.add_member(current_user, :developer)
      end

      it 'generates an error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) { resolve_scope }
      end
    end
  end
end
