# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::AlertManagementAlertResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert_1) { create(:alert_management_alert, :resolved, project: project, ended_at: 1.year.ago, events: 2, severity: :high) }
  let_it_be(:alert_2) { create(:alert_management_alert, :ignored, project: project, events: 1, severity: :critical) }
  let_it_be(:alert_other_proj) { create(:alert_management_alert) }

  let(:args) { {} }

  subject { resolve_alerts(args) }

  context 'user does not have permission' do
    it { is_expected.to eq(AlertManagement::Alert.none) }
  end

  context 'user has permission' do
    before do
      project.add_developer(current_user)
    end

    it { is_expected.to contain_exactly(alert_1, alert_2) }

    context 'finding by iid' do
      let(:args) { { iid: alert_1.iid } }

      it { is_expected.to contain_exactly(alert_1) }
    end

    context 'finding by status' do
      let(:args) { { status: [Types::AlertManagement::StatusEnum.values['IGNORED'].value] } }

      it { is_expected.to contain_exactly(alert_2) }
    end

    describe 'sorting' do
      # Other sorting examples in spec/finders/alert_management/alerts_finder_spec.rb
      context 'when sorting by events count' do
        let_it_be(:alert_count_6) { create(:alert_management_alert, project: project, events: 6) }
        let_it_be(:alert_count_3) { create(:alert_management_alert, project: project, events: 3) }

        it 'sorts alerts ascending' do
          expect(resolve_alerts(sort: :event_count_asc)).to eq [alert_2, alert_1, alert_count_3, alert_count_6]
        end

        it 'sorts alerts descending' do
          expect(resolve_alerts(sort: :event_count_desc)).to eq [alert_count_6, alert_count_3, alert_1, alert_2]
        end
      end
    end
  end

  private

  def resolve_alerts(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
