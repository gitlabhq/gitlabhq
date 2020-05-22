# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::Projects::JiraProjectsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    shared_examples 'no project service access' do
      it 'raises error' do
        expect do
          resolve_jira_projects
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when project has no jira service' do
      let_it_be(:jira_service) { nil }

      context 'when user is a maintainer' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'no project service access'
      end
    end

    context 'when project has jira service' do
      let(:jira_service) { create(:jira_service, project: project) }

      context 'when user is a developer' do
        before do
          project.add_developer(user)
        end

        it_behaves_like 'no project service access'
      end

      context 'when user is a maintainer' do
        include_context 'jira projects request context'

        before do
          project.add_maintainer(user)
        end

        it 'returns jira projects' do
          jira_projects = resolve_jira_projects
          project_keys = jira_projects.map(&:key)
          project_names = jira_projects.map(&:name)
          project_ids = jira_projects.map(&:id)

          expect(jira_projects.size).to eq 2
          expect(project_keys).to eq(%w(EX ABC))
          expect(project_names).to eq(%w(Example Alphabetical))
          expect(project_ids).to eq(%w(10000 10001))
        end
      end
    end
  end

  def resolve_jira_projects(args = {}, context = { current_user: user })
    resolve(described_class, obj: jira_service, args: args, ctx: context)
  end
end
