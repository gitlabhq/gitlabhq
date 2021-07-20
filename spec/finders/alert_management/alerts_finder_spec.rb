# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertsFinder, '#execute' do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:resolved_alert) { create(:alert_management_alert, :all_fields, :resolved, project: project, ended_at: 1.year.ago, events: 2, severity: :high) }
  let_it_be(:ignored_alert) { create(:alert_management_alert, :all_fields, :ignored, project: project, events: 1, severity: :critical) }
  let_it_be(:triggered_alert) { create(:alert_management_alert, :all_fields) }
  let_it_be(:threat_monitroing_alert) { create(:alert_management_alert, domain: 'threat_monitoring') }

  let(:params) { {} }

  describe '#execute' do
    subject(:execute) { described_class.new(current_user, project, params).execute }

    context 'user is not a developer or above' do
      it { is_expected.to be_empty }
    end

    context 'user is developer' do
      before do
        project.add_developer(current_user)
      end

      context 'domain' do
        context 'domain is threat management' do
          let(:params) { { domain: 'threat_management' } }

          it { is_expected.to contain_exactly(resolved_alert, ignored_alert) }
        end

        context 'domain is unknown' do
          let(:params) { { domain: 'unkown' } }

          it { is_expected.to contain_exactly(resolved_alert, ignored_alert) }
        end

        context 'domain is missing' do
          let(:params) { {} }

          it { is_expected.to contain_exactly(resolved_alert, ignored_alert) }
        end

        context 'skips domain if iid is given' do
          let(:params) { { iid: resolved_alert.iid, domain: 'threat_monitoring' } }

          it { is_expected.to contain_exactly(resolved_alert) }
        end
      end

      context 'empty params' do
        it { is_expected.to contain_exactly(resolved_alert, ignored_alert) }
      end

      context 'iid given' do
        let(:params) { { iid: resolved_alert.iid } }

        it { is_expected.to match_array(resolved_alert) }

        context 'unknown iid' do
          let(:params) { { iid: 'unknown' } }

          it { is_expected.to be_empty }
        end
      end

      context 'status given' do
        let(:params) { { status: :resolved } }

        it { is_expected.to match_array(resolved_alert) }

        context 'with an array of statuses' do
          let(:triggered_alert) { create(:alert_management_alert) }
          let(:params) { { status: [:resolved] } }

          it { is_expected.to match_array(resolved_alert) }
        end

        context 'with no alerts of status' do
          let(:params) { { status: :acknowledged } }

          it { is_expected.to be_empty }
        end

        context 'with an empty status array' do
          let(:params) { { status: [] } }

          it { is_expected.to match_array([resolved_alert, ignored_alert]) }
        end

        context 'with an nil status' do
          let(:params) { { status: nil } }

          it { is_expected.to match_array([resolved_alert, ignored_alert]) }
        end
      end

      describe 'sorting' do
        context 'when sorting by created' do
          context 'sorts alerts ascending' do
            let(:params) { { sort: 'created_asc' } }

            it { is_expected.to eq [resolved_alert, ignored_alert] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'created_desc' } }

            it { is_expected.to eq [ignored_alert, resolved_alert] }
          end
        end

        context 'when sorting by updated' do
          context 'sorts alerts ascending' do
            let(:params) { { sort: 'updated_asc' } }

            it { is_expected.to eq [resolved_alert, ignored_alert] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'updated_desc' } }

            it { is_expected.to eq [ignored_alert, resolved_alert] }
          end
        end

        context 'when sorting by start time' do
          context 'sorts alerts ascending' do
            let(:params) { { sort: 'started_at_asc' } }

            it { is_expected.to eq [resolved_alert, ignored_alert] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'started_at_desc' } }

            it { is_expected.to eq [ignored_alert, resolved_alert] }
          end
        end

        context 'when sorting by end time' do
          context 'sorts alerts ascending' do
            let(:params) { { sort: 'ended_at_asc' } }

            it { is_expected.to eq [resolved_alert, ignored_alert] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'ended_at_desc' } }

            it { is_expected.to eq [ignored_alert, resolved_alert] }
          end
        end

        context 'when sorting by events count' do
          let_it_be(:alert_count_6) { create(:alert_management_alert, project: project, events: 6) }
          let_it_be(:alert_count_3) { create(:alert_management_alert, project: project, events: 3) }

          context 'sorts alerts ascending' do
            let(:params) { { sort: 'event_count_asc' } }

            it { is_expected.to eq [ignored_alert, resolved_alert, alert_count_3, alert_count_6] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'event_count_desc' } }

            it { is_expected.to eq [alert_count_6, alert_count_3, resolved_alert, ignored_alert] }
          end
        end

        context 'when sorting by severity' do
          let_it_be(:alert_critical) { create(:alert_management_alert, :critical, project: project) }
          let_it_be(:alert_high) { create(:alert_management_alert, :high, project: project) }
          let_it_be(:alert_medium) { create(:alert_management_alert, :medium, project: project) }
          let_it_be(:alert_low) { create(:alert_management_alert, :low, project: project) }
          let_it_be(:alert_info) { create(:alert_management_alert, :info, project: project) }
          let_it_be(:alert_unknown) { create(:alert_management_alert, :unknown, project: project) }

          context 'with ascending sort order' do
            let(:params) { { sort: 'severity_asc' } }

            it 'sorts alerts by severity from less critical to more critical' do
              expect(execute.pluck(:severity).uniq).to eq(%w(unknown info low medium high critical))
            end
          end

          context 'with descending sort order' do
            let(:params) { { sort: 'severity_desc' } }

            it 'sorts alerts by severity from more critical to less critical' do
              expect(execute.pluck(:severity).uniq).to eq(%w(critical high medium low info unknown))
            end
          end
        end

        context 'when sorting by status' do
          let_it_be(:alert_triggered) { create(:alert_management_alert, project: project) }
          let_it_be(:alert_acknowledged) { create(:alert_management_alert, :acknowledged, project: project) }
          let_it_be(:alert_resolved) { create(:alert_management_alert, :resolved, project: project) }
          let_it_be(:alert_ignored) { create(:alert_management_alert, :ignored, project: project) }

          context 'with ascending sort order' do
            let(:params) { { sort: 'status_asc' } }

            it 'sorts by status: Ignored > Resolved > Acknowledged > Triggered' do
              expect(execute.map(&:status_name).uniq).to eq([:ignored, :resolved, :acknowledged, :triggered])
            end
          end

          context 'with descending sort order' do
            let(:params) { { sort: 'status_desc' } }

            it 'sorts by status: Triggered > Acknowledged > Resolved > Ignored' do
              expect(execute.map(&:status_name).uniq).to eq([:triggered, :acknowledged, :resolved, :ignored])
            end
          end
        end
      end

      context 'search query given' do
        let_it_be(:alert) do
          create(:alert_management_alert,
                 :with_fingerprint,
                 project: project,
                 title: 'Title',
                 description: 'Desc',
                 service: 'Service',
                 monitoring_tool: 'Monitor'
                )
        end

        context 'searching title' do
          let(:params) { { search: alert.title } }

          it { is_expected.to match_array([alert]) }
        end

        context 'searching description' do
          let(:params) { { search: alert.description } }

          it { is_expected.to match_array([alert]) }
        end

        context 'searching service' do
          let(:params) { { search: alert.service } }

          it { is_expected.to match_array([alert]) }
        end

        context 'searching monitoring tool' do
          let(:params) { { search: alert.monitoring_tool } }

          it { is_expected.to match_array([alert]) }
        end

        context 'searching something else' do
          let(:params) { { search: alert.fingerprint } }

          it { is_expected.to be_empty }
        end
      end

      context 'assignee username given' do
        let_it_be(:assignee) { create(:user) }
        let_it_be(:alert) { create(:alert_management_alert, project: project, assignees: [assignee]) }

        let(:params) { { assignee_username: username } }

        context 'with valid assignee_username' do
          let(:username) { assignee.username }

          it { is_expected.to match_array([alert]) }
        end

        context 'with invalid assignee_username' do
          let(:username) { 'unknown username' }

          it { is_expected.to be_empty }
        end
      end
    end
  end

  describe '.counts_by_status' do
    subject { described_class.counts_by_status(current_user, project, params) }

    before do
      project.add_developer(current_user)
    end

    it { is_expected.to match(resolved: 1, ignored: 1) }

    context 'when filtering params are included' do
      let(:params) { { status: :resolved } }

      it { is_expected.to match(resolved: 1) }
    end
  end
end
