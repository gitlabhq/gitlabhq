# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::Projects::JiraImportsResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:jira_import_data) do
      data = JiraImportData.new
      data << JiraImportData::JiraProjectDetails.new('AA', 2.days.ago.strftime('%Y-%m-%d %H:%M:%S'), { user_id: user.id, name: user.name })
      data << JiraImportData::JiraProjectDetails.new('BB', 5.days.ago.strftime('%Y-%m-%d %H:%M:%S'), { user_id: user.id, name: user.name })
      data
    end

    context 'when feature flag disabled' do
      let_it_be(:project) { create(:project, :private, import_data: jira_import_data) }

      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'no jira import access'
    end

    context 'when project does not have Jira import data' do
      let_it_be(:project) { create(:project, :private, import_data: nil) }

      context 'when user cannot read Jira import data' do
        context 'when anonymous user' do
          it_behaves_like 'no jira import data present'
        end

        context 'when user developer' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'no jira import data present'
        end
      end

      context 'when user can read Jira import data' do
        before do
          project.add_maintainer(user)
        end

        it_behaves_like 'no jira import data present'
      end
    end

    context 'when project has Jira import data' do
      let_it_be(:project) { create(:project, :private, import_data: jira_import_data) }

      context 'when user cannot read Jira import data' do
        context 'when anonymous user' do
          it_behaves_like 'no jira import access'
        end

        context 'when user developer' do
          before do
            project.add_developer(user)
          end

          it_behaves_like 'no jira import access'
        end
      end

      context 'when user can access Jira import data' do
        before do
          project.add_maintainer(user)
        end

        it 'returns Jira imports sorted ascending by scheduledAt time' do
          imports = resolve_imports

          expect(imports.size).to eq 2
          expect(imports.map(&:key)).to eq %w(BB AA)
        end
      end
    end
  end

  def resolve_imports(args = {}, context = { current_user: user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
