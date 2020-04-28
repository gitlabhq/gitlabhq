# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::AlertsFinder, '#execute' do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:alert_1) { create(:alert_management_alert, project: project) }
  let_it_be(:alert_2) { create(:alert_management_alert, project: project) }
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
  end
end
