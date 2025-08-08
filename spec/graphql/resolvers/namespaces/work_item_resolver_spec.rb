# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Namespaces::WorkItemResolver, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  before_all do
    group.add_developer(current_user)
  end

  def resolve_work_item(obj, args = {})
    resolve(described_class, obj: obj, args: args, ctx: { current_user: current_user }, arg_style: :internal)
  end

  describe '#resolve' do
    context 'with a project namespace' do
      let(:namespace) { project.project_namespace }
      let_it_be(:work_item) { create(:work_item, project: project) }

      it 'returns the work item' do
        result = resolve_work_item(namespace, { iid: work_item.iid.to_s })

        expect(result).to eq(work_item)
      end

      context 'when work item does not exist' do
        it 'returns nil' do
          result = resolve_work_item(namespace, { iid: '999' })

          expect(result).to be_nil
        end
      end

      context 'when current_user is nil' do
        it 'returns the work item but does not log recent view' do
          result = resolve(described_class, obj: namespace, args: { iid: work_item.iid.to_s },
            ctx: { current_user: nil })

          expect(result).to eq(work_item)
        end
      end

      describe 'recent items logging' do
        context 'with an issue work item' do
          let_it_be(:issue_work_item) { create(:work_item, :issue, project: project) }

          it 'logs the issue to recent items' do
            recent_issues_service = instance_double(::Gitlab::Search::RecentIssues)
            expect(::Gitlab::Search::RecentIssues).to receive(:new).with(user: current_user)
              .and_return(recent_issues_service)
            expect(recent_issues_service).to receive(:log_view).with(issue_work_item)

            result = resolve_work_item(namespace, { iid: issue_work_item.iid.to_s })

            expect(result).to eq(issue_work_item)
          end
        end

        context 'with a task work item (unsupported)' do
          let_it_be(:task_work_item) { create(:work_item, :task, project: project) }

          it 'does not log to recent items' do
            expect(::Gitlab::Search::RecentIssues).not_to receive(:new)

            result = resolve_work_item(namespace, { iid: task_work_item.iid.to_s })

            expect(result).to eq(task_work_item)
          end
        end
      end
    end

    context 'with a group namespace' do
      let(:namespace) { group }
      let_it_be(:epic_work_item) { create(:work_item, :epic, namespace: group) }

      context 'when epics are not available' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'does not return the epic work item' do
          result = resolve_work_item(namespace, { iid: epic_work_item.iid.to_s })

          expect(result).to be_nil
        end
      end
    end
  end

  describe 'recent_services_map' do
    it 'maps issue base type to RecentIssues service' do
      expect(described_class.recent_services_map['issue']).to eq(::Gitlab::Search::RecentIssues)
    end

    it 'does not include unsupported work item types' do
      expect(described_class.recent_services_map).not_to have_key('task')
      expect(described_class.recent_services_map).not_to have_key('incident')
    end
  end

  describe 'integration tests for recent items' do
    context 'when service class is not available' do
      let_it_be(:issue_work_item) { create(:work_item, :issue, project: project) }

      it 'does not fail when RecentIssues is not defined' do
        # Temporarily hide the RecentIssues constant
        allow(described_class).to receive(:recent_services_map).and_return({})
        result = resolve_work_item(project.project_namespace, { iid: issue_work_item.iid.to_s })

        expect(result).to eq(issue_work_item)
      end
    end

    context 'when current_user is nil' do
      let_it_be(:issue_work_item) { create(:work_item, :issue, project: project) }

      it 'does not try to log recent items' do
        expect(::Gitlab::Search::RecentIssues).not_to receive(:new)

        result = resolve(described_class, obj: project.project_namespace, args: { iid: issue_work_item.iid.to_s },
          ctx: { current_user: nil })

        expect(result).to eq(issue_work_item)
      end
    end
  end
end
