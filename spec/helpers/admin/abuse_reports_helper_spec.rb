# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportsHelper, feature_category: :insider_threat do
  describe '#abuse_reports_list_data' do
    let!(:report) { create(:abuse_report) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
    let(:reports) { AbuseReport.all.page(1) }
    let(:data) do
      data = helper.abuse_reports_list_data(reports)[:abuse_reports_data]
      Gitlab::Json.parse(data)
    end

    it 'has expected attributes', :aggregate_failures do
      expect(data['pagination']).to include(
        "current_page" => 1,
        "per_page" => 20,
        "total_items" => 1
      )
      expect(data['reports'].first).to include("category", "updated_at", "reported_user", "reporter")
      expect(data['categories']).to match_array(AbuseReport.categories.keys)
    end
  end

  describe '#abuse_report_data' do
    let(:report) { build_stubbed(:abuse_report) }

    subject(:data) { helper.abuse_report_data(report) }

    it 'has the expected attributes' do
      expect(data[:abuse_report_data]).to include('user', 'reporter', 'report')
    end

    it 'includes path to abuse reports list page' do
      expect(data[:abuse_reports_list_path]).to eq admin_abuse_reports_path
    end
  end
end
