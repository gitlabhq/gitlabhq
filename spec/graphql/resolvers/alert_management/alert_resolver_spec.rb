# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::AlertManagement::AlertResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:resolved_alert) { create(:alert_management_alert, :resolved, project: project, ended_at: 1.year.ago, events: 2, severity: :high) }
  let_it_be(:ignored_alert) { create(:alert_management_alert, :ignored, project: project, events: 1, severity: :critical) }
  let_it_be(:alert_other_proj) { create(:alert_management_alert) }

  let(:args) { {} }

  subject { resolve_alerts_for(project, args) }

  context 'hide_incident_management_features flag disabled' do
    before do
      stub_feature_flags(hide_incident_management_features: false)
    end

    context 'user does not have permission' do
      it { is_expected.to eq(AlertManagement::Alert.none) }
    end

    context 'user has permission' do
      before do
        project.add_developer(current_user)
      end

      it { is_expected.to contain_exactly(resolved_alert, ignored_alert) }

      context 'finding by iid' do
        let(:args) { { iid: resolved_alert.iid } }

        it { is_expected.to contain_exactly(resolved_alert) }
      end

      context 'finding by status' do
        let(:args) { { statuses: [Types::AlertManagement::StatusEnum.values['IGNORED'].value] } }

        it { is_expected.to contain_exactly(ignored_alert) }
      end

      context 'filtering by domain' do
        let_it_be(:alert1) { create(:alert_management_alert, project: project, monitoring_tool: 'other', domain: :threat_monitoring) }
        let_it_be(:alert2) { create(:alert_management_alert, project: project, monitoring_tool: 'other', domain: :threat_monitoring) }
        let_it_be(:alert3) { create(:alert_management_alert, project: project, monitoring_tool: 'generic') }

        let(:args) { { domain: 'operations' } }

        it { is_expected.to contain_exactly(resolved_alert, ignored_alert, alert3) }
      end

      describe 'sorting' do
        # Other sorting examples in spec/finders/alert_management/alerts_finder_spec.rb
        context 'when sorting by events count' do
          let_it_be(:alert_count_6) { create(:alert_management_alert, project: project, events: 6) }
          let_it_be(:alert_count_3) { create(:alert_management_alert, project: project, events: 3) }

          it 'sorts alerts ascending' do
            expect(resolve_alerts_for(project, sort: :event_count_asc)).to eq [ignored_alert, resolved_alert, alert_count_3, alert_count_6]
          end

          it 'sorts alerts descending' do
            expect(resolve_alerts_for(project, sort: :event_count_desc)).to eq [alert_count_6, alert_count_3, resolved_alert, ignored_alert]
          end
        end
      end
    end
  end

  context 'when parent is an Issue' do
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:alert) { create(:alert_management_alert, project: project, issue: issue) }

    before do
      stub_feature_flags(hide_incident_management_features: false)
    end

    context 'when user does not have permission' do
      it 'returns empty association' do
        issue.association(:alert_management_alerts).load_target

        result = resolve_alerts_for(issue)

        expect(result).to eq(::AlertManagement::Alert.none)
      end
    end

    context 'when user has permission' do
      before do
        project.add_developer(current_user)
      end

      context 'when alert_management_alerts association is preloaded' do
        it 'returns the preloaded alerts without using AlertsFinder' do
          issue.association(:alert_management_alerts).load_target

          expect(::AlertManagement::AlertsFinder).not_to receive(:new)

          result = resolve_alerts_for(issue)

          expect(result).to contain_exactly(alert)
        end
      end

      context 'when alert_management_alerts association is not preloaded' do
        it 'falls through to AlertsFinder' do
          fresh_issue = Issue.find(issue.id)

          expect(::AlertManagement::AlertsFinder).to receive(:new).and_call_original

          result = resolve_alerts_for(fresh_issue)

          expect(result).to contain_exactly(alert)
        end
      end

      context 'when alert_management_alerts association is preloaded and there are arguments in the request' do
        it 'falls through to AlertsFinder' do
          issue.association(:alert_management_alerts).load_target

          expect(::AlertManagement::AlertsFinder).to receive(:new).and_call_original

          result = resolve_alerts_for(issue, sort: :event_count_desc)

          expect(result).to contain_exactly(alert)
        end
      end
    end
  end

  context 'when hide_incident_management_features is enabled' do
    before do
      project.add_developer(current_user)
    end

    it 'returns a GraphQL::ExecutionError' do
      result = resolve_alerts_for(project)
      expect(result).to be_a(GraphQL::ExecutionError)
      expect(result.message).to eq("Field 'alertManagementAlerts' doesn't exist on type 'Project'.")
    end
  end

  private

  def resolve_alerts_for(object, args = {}, context = { current_user: current_user })
    resolve(described_class, obj: object, args: args, ctx: context, arg_style: :internal)
  end
end
