# frozen_string_literal: true

require 'spec_helper'

describe AbuseReportsFinder, '#execute' do
  let(:params) { {} }
  let!(:user1) { create(:user) }
  let!(:user2) { create(:user) }
  let!(:abuse_report_1) { create(:abuse_report, user: user1) }
  let!(:abuse_report_2) { create(:abuse_report, user: user2) }

  subject { described_class.new(params).execute }

  context 'empty params' do
    it 'returns all abuse reports' do
      expect(subject).to match_array([abuse_report_1, abuse_report_2])
    end
  end

  context 'params[:user_id] is present' do
    let(:params) { { user_id: user2 } }

    it 'returns abuse reports for the specified user' do
      expect(subject).to match_array([abuse_report_2])
    end
  end
end
