# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::Projects::JiraImportsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project, reload: true) { create(:project, :public) }

    context 'when project does not have Jira imports' do
      let(:current_user) { user }

      context 'when user cannot read Jira imports' do
        context 'when anonymous user' do
          let(:current_user) { nil }

          it_behaves_like 'no Jira import access'
        end
      end

      context 'when user can read Jira import data' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'no Jira import data present'

        it 'does not raise access error' do
          expect do
            resolve_imports
          end.not_to raise_error
        end
      end
    end

    context 'when project has Jira imports' do
      let_it_be(:current_user) { user }
      let_it_be(:jira_import1) { create(:jira_import_state, :finished, project: project, jira_project_key: 'AA', created_at: 2.days.ago) }
      let_it_be(:jira_import2) { create(:jira_import_state, :finished, project: project, jira_project_key: 'BB', created_at: 5.days.ago) }

      context 'when feature flag disabled' do
        let(:current_user) { user }

        before do
          stub_feature_flags(jira_issue_import: false)
        end

        it_behaves_like 'no Jira import access'
      end

      context 'when user cannot read Jira imports' do
        context 'when anonymous user' do
          let(:current_user) { nil }

          it_behaves_like 'no Jira import access'
        end
      end

      context 'when user can access Jira imports' do
        before do
          project.add_guest(user)
        end

        it 'returns Jira imports sorted ascending by created_at time' do
          imports = resolve_imports

          expect(imports.size).to eq 2
          expect(imports.map(&:jira_project_key)).to eq %w(BB AA)
        end
      end
    end
  end

  def resolve_imports(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
