# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::AlertManagementAlertResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert_1) { create(:alert_management_alert, project: project) }
  let_it_be(:alert_2) { create(:alert_management_alert, project: project) }
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
  end

  private

  def resolve_alerts(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
