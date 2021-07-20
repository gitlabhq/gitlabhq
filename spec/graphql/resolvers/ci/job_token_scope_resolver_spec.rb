# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::JobTokenScopeResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, ci_job_token_scope_enabled: true).tap(&:save!) }

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::Ci::JobTokenScopeType)
  end

  subject(:resolve_scope) { resolve(described_class, ctx: { current_user: current_user }, obj: project) }

  describe '#resolve' do
    context 'with access to scope' do
      before do
        project.add_user(current_user, :maintainer)
      end

      it 'returns nil when scope is not enabled' do
        allow(project).to receive(:ci_job_token_scope_enabled?).and_return(false)

        expect(resolve_scope).to eq(nil)
      end

      it 'returns the same project in the allow list of projects for the Ci Job Token' do
        expect(resolve_scope.all_projects).to contain_exactly(project)
      end

      context 'when another projects gets added to the allow list' do
        let!(:link) { create(:ci_job_token_project_scope_link, source_project: project) }

        it 'returns both projects' do
          expect(resolve_scope.all_projects).to contain_exactly(project, link.target_project)
        end
      end

      context 'when job token scope is disabled' do
        before do
          project.update!(ci_job_token_scope_enabled: false)
        end

        it 'returns nil' do
          expect(resolve_scope).to be_nil
        end
      end
    end

    context 'without access to scope' do
      before do
        project.add_user(current_user, :developer)
      end

      it 'raises error' do
        expect do
          resolve_scope
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
