# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertsFinder, '#execute' do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert_1) { create(:alert_management_alert, :all_fields, :resolved, project: project, ended_at: 1.year.ago, events: 2, severity: :high) }
  let_it_be(:alert_2) { create(:alert_management_alert, :all_fields, :ignored, project: project, events: 1, severity: :critical) }
  let_it_be(:alert_3) { create(:alert_management_alert, :all_fields) }
  let(:params) { {} }

  describe '#execute' do
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

      context 'status given' do
        let(:params) { { status: AlertManagement::Alert::STATUSES[:resolved] } }

        it { is_expected.to match_array(alert_1) }

        context 'with an array of statuses' do
          let(:alert_3) { create(:alert_management_alert) }
          let(:params) { { status: [AlertManagement::Alert::STATUSES[:resolved]] } }

          it { is_expected.to match_array(alert_1) }
        end

        context 'with no alerts of status' do
          let(:params) { { status: AlertManagement::Alert::STATUSES[:acknowledged] } }

          it { is_expected.to be_empty }
        end

        context 'with an empty status array' do
          let(:params) { { status: [] } }

          it { is_expected.to match_array([alert_1, alert_2]) }
        end

        context 'with an nil status' do
          let(:params) { { status: nil } }

          it { is_expected.to match_array([alert_1, alert_2]) }
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
            let(:params) { { sort: 'started_at_asc' } }

            it { is_expected.to eq [alert_1, alert_2] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'started_at_desc' } }

            it { is_expected.to eq [alert_2, alert_1] }
          end
        end

        context 'when sorting by end time' do
          context 'sorts alerts ascending' do
            let(:params) { { sort: 'ended_at_asc' } }

            it { is_expected.to eq [alert_1, alert_2] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'ended_at_desc' } }

            it { is_expected.to eq [alert_2, alert_1] }
          end
        end

        context 'when sorting by events count' do
          let_it_be(:alert_count_6) { create(:alert_management_alert, project: project, events: 6) }
          let_it_be(:alert_count_3) { create(:alert_management_alert, project: project, events: 3) }

          context 'sorts alerts ascending' do
            let(:params) { { sort: 'event_count_asc' } }

            it { is_expected.to eq [alert_2, alert_1, alert_count_3, alert_count_6] }
          end

          context 'sorts alerts descending' do
            let(:params) { { sort: 'event_count_desc' } }

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
          let_it_be(:alert_triggered) { create(:alert_management_alert, project: project) }
          let_it_be(:alert_acknowledged) { create(:alert_management_alert, :acknowledged, project: project) }
          let_it_be(:alert_resolved) { create(:alert_management_alert, :resolved, project: project) }
          let_it_be(:alert_ignored) { create(:alert_management_alert, :ignored, project: project) }

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

    context 'search query given' do
      let_it_be(:alert) do
        create(:alert_management_alert,
          :with_fingerprint,
          title: 'Title',
          description: 'Desc',
          service: 'Service',
          monitoring_tool: 'Monitor'
        )
      end

      before do
        alert.project.add_developer(current_user)
      end

      subject { described_class.new(current_user, alert.project, params).execute }

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

      context 'empty search' do
        let(:params) { { search: ' ' } }

        it { is_expected.to match_array([alert]) }
      end
    end
  end

  describe '.counts_by_status' do
    subject { described_class.counts_by_status(current_user, project, params) }

    before do
      project.add_developer(current_user)
    end

    it { is_expected.to match({ 2 => 1, 3 => 1 }) } # one resolved and one ignored

    context 'when filtering params are included' do
      let(:params) { { status: AlertManagement::Alert::STATUSES[:resolved] } }

      it { is_expected.to match({ 2 => 1 }) } # one resolved
    end
  end
end
