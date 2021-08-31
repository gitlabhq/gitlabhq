# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ErrorsFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:error) { create(:error_tracking_error, project: project) }
  let_it_be(:error_resolved) { create(:error_tracking_error, :resolved, project: project) }
  let_it_be(:error_yesterday) { create(:error_tracking_error, project: project, first_seen_at: Time.zone.now.yesterday) }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    let(:params) { {} }

    subject { described_class.new(user, project, params).execute }

    it { is_expected.to contain_exactly(error, error_resolved, error_yesterday) }

    context 'with status parameter' do
      let(:params) { { status: 'resolved' } }

      it { is_expected.to contain_exactly(error_resolved) }
    end

    context 'with sort parameter' do
      let(:params) { { status: 'unresolved', sort: 'first_seen' } }

      it { is_expected.to eq([error, error_yesterday]) }
    end

    context 'with limit parameter' do
      let(:params) { { limit: '1', sort: 'first_seen' } }

      it { is_expected.to contain_exactly(error) }
    end
  end
end
