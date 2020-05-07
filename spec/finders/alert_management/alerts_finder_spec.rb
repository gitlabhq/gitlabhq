# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertsFinder, '#execute' do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert_1) { create(:alert_management_alert, project: project, ended_at: 1.year.ago, events: 2, severity: :high, status: :resolved) }
  let_it_be(:alert_2) { create(:alert_management_alert, project: project, events: 1, severity: :critical, status: :ignored) }
  let_it_be(:alert_3) { create(:alert_management_alert) }
  let(:params) { {} }

  subject { described_class.new(current_user, project, params).execute }

  context 'user is not a developer or above' do
    it { is_expected.to be_empty }
  end

  context 'user is developer' do
    before do
      project.add_developer(current_user)
    end

    context 'empty params' do
      it { is_expected.to contain_exactly(alert_1, alert_2) }
    end

    context 'iid given' do
      let(:params) { { iid: alert_1.iid } }

      it { is_expected.to match_array(alert_1) }

      context 'unknown iid' do
        let(:params) { { iid: 'unknown' } }

        it { is_expected.to be_empty }
      end
    end

    describe 'sorting' do
      context 'when sorting by created' do
        context 'sorts alerts ascending' do
          let(:params) { { sort: 'created_asc' } }

          it { is_expected.to eq [alert_1, alert_2] }
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'created_desc' } }

          it { is_expected.to eq [alert_2, alert_1] }
        end
      end

      context 'when sorting by updated' do
        context 'sorts alerts ascending' do
          let(:params) { { sort: 'updated_asc' } }

          it { is_expected.to eq [alert_1, alert_2] }
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'updated_desc' } }

          it { is_expected.to eq [alert_2, alert_1] }
        end
      end

      context 'when sorting by start time' do
        context 'sorts alerts ascending' do
          let(:params) { { sort: 'start_time_asc' } }

          it { is_expected.to eq [alert_1, alert_2] }
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'start_time_desc' } }

          it { is_expected.to eq [alert_2, alert_1] }
        end
      end

      context 'when sorting by end time' do
        context 'sorts alerts ascending' do
          let(:params) { { sort: 'end_time_asc' } }

          it { is_expected.to eq [alert_1, alert_2] }
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'end_time_desc' } }

          it { is_expected.to eq [alert_2, alert_1] }
        end
      end

      context 'when sorting by events count' do
        let_it_be(:alert_count_6) { create(:alert_management_alert, project: project, events: 6) }
        let_it_be(:alert_count_3) { create(:alert_management_alert, project: project, events: 3) }

        context 'sorts alerts ascending' do
          let(:params) { { sort: 'events_count_asc' } }

          it { is_expected.to eq [alert_2, alert_1, alert_count_3, alert_count_6] }
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'events_count_desc' } }

          it { is_expected.to eq [alert_count_6, alert_count_3, alert_1, alert_2] }
        end
      end

      context 'when sorting by severity' do
        let_it_be(:alert_critical) { create(:alert_management_alert, project: project, severity: :critical) }
        let_it_be(:alert_high) { create(:alert_management_alert, project: project, severity: :high) }
        let_it_be(:alert_medium) { create(:alert_management_alert, project: project, severity: :medium) }
        let_it_be(:alert_low) { create(:alert_management_alert, project: project, severity: :low) }
        let_it_be(:alert_info) { create(:alert_management_alert, project: project, severity: :info) }
        let_it_be(:alert_unknown) { create(:alert_management_alert, project: project, severity: :unknown) }

        context 'sorts alerts ascending' do
          let(:params) { { sort: 'severity_asc' } }

          it do
            is_expected.to eq [
              alert_2,
              alert_critical,
              alert_1,
              alert_high,
              alert_medium,
              alert_low,
              alert_info,
              alert_unknown
            ]
          end
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'severity_desc' } }

          it do
            is_expected.to eq [
              alert_unknown,
              alert_info,
              alert_low,
              alert_medium,
              alert_1,
              alert_high,
              alert_critical,
              alert_2
            ]
          end
        end
      end

      context 'when sorting by status' do
        let_it_be(:alert_triggered) { create(:alert_management_alert, project: project, status: :triggered) }
        let_it_be(:alert_acknowledged) { create(:alert_management_alert, project: project, status: :acknowledged) }
        let_it_be(:alert_resolved) { create(:alert_management_alert, project: project, status: :resolved) }
        let_it_be(:alert_ignored) { create(:alert_management_alert, project: project, status: :ignored) }

        context 'sorts alerts ascending' do
          let(:params) { { sort: 'status_asc' } }

          it do
            is_expected.to eq [
              alert_triggered,
              alert_acknowledged,
              alert_1,
              alert_resolved,
              alert_2,
              alert_ignored
            ]
          end
        end

        context 'sorts alerts descending' do
          let(:params) { { sort: 'status_desc' } }

          it do
            is_expected.to eq [
              alert_2,
              alert_ignored,
              alert_1,
              alert_resolved,
              alert_acknowledged,
              alert_triggered
            ]
          end
        end
      end
    end
  end
end
