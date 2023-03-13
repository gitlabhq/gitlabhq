# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportsFinder, '#execute' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:abuse_report_1) { create(:abuse_report, id: 20, category: 'spam', user: user1) }
  let_it_be(:abuse_report_2) { create(:abuse_report, :closed, id: 30, category: 'phishing', user: user2) }

  let(:params) { {} }

  subject { described_class.new(params).execute }

  context 'when params is empty' do
    it 'returns all abuse reports' do
      expect(subject).to match_array([abuse_report_1, abuse_report_2])
    end
  end

  context 'when params[:user_id] is present' do
    let(:params) { { user_id: user2 } }

    it 'returns abuse reports for the specified user' do
      expect(subject).to match_array([abuse_report_2])
    end
  end

  context 'when params[:user] is present' do
    let(:params) { { user: abuse_report_1.user.username } }

    it 'returns abuse reports for the specified user' do
      expect(subject).to match_array([abuse_report_1])
    end

    context 'when no user has username = params[:user]' do
      before do
        allow(User).to receive_message_chain(:by_username, :pick)
          .with(params[:user])
          .with(:id)
          .and_return(nil)
      end

      it 'returns all abuse reports' do
        expect(subject).to match_array([abuse_report_1, abuse_report_2])
      end
    end
  end

  context 'when params[:status] is present' do
    context 'when value is "open"' do
      let(:params) { { status: 'open' } }

      it 'returns only open abuse reports' do
        expect(subject).to match_array([abuse_report_1])
      end
    end

    context 'when value is "closed"' do
      let(:params) { { status: 'closed' } }

      it 'returns only closed abuse reports' do
        expect(subject).to match_array([abuse_report_2])
      end
    end
  end

  context 'when params[:category] is present' do
    let(:params) { { category: 'phishing' } }

    it 'returns abuse reports with the specified category' do
      expect(subject).to match_array([abuse_report_2])
    end
  end

  describe 'sorting' do
    let(:params) { { sort: 'created_at_asc' } }

    it 'returns reports sorted by the specified sort attribute' do
      expect(subject).to eq [abuse_report_1, abuse_report_2]
    end

    context 'when sort is not specified' do
      let(:params) { {} }

      it "returns reports sorted by #{described_class::DEFAULT_SORT}" do
        expect(subject).to eq [abuse_report_2, abuse_report_1]
      end
    end

    context 'when sort is not supported' do
      let(:params) { { sort: 'superiority' } }

      it "returns reports sorted by #{described_class::DEFAULT_SORT}" do
        expect(subject).to eq [abuse_report_2, abuse_report_1]
      end
    end

    context 'when abuse_reports_list feature flag is disabled' do
      let_it_be(:abuse_report_3) { create(:abuse_report, id: 10) }

      before do
        stub_feature_flags(abuse_reports_list: false)
      end

      it 'returns reports sorted by id in descending order' do
        expect(subject).to eq [abuse_report_2, abuse_report_1, abuse_report_3]
      end
    end
  end
end
