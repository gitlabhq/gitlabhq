# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::ErrorsFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:error) { create(:error_tracking_error, project: project) }
  let_it_be(:error_resolved) { create(:error_tracking_error, :resolved, project: project, first_seen_at: 2.hours.ago) }
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

      it { expect(subject.to_a).to eq([error, error_yesterday]) }
    end

    context 'pagination' do
      let(:params) { { limit: '1', sort: 'first_seen' } }

      # Sort by first_seen is DESC by default, so the most recent error is `error`
      it { is_expected.to contain_exactly(error) }

      it { expect(subject.has_next_page?).to be_truthy }

      it 'returns next page by cursor' do
        params_with_cursor = params.merge(cursor: subject.cursor_for_next_page)
        errors = described_class.new(user, project, params_with_cursor).execute

        expect(errors).to contain_exactly(error_resolved)
        expect(errors.has_next_page?).to be_truthy
        expect(errors.has_previous_page?).to be_truthy
      end
    end
  end
end
