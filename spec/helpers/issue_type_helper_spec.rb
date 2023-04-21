# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueTypeHelper, feature_category: :team_planning do
  describe '.issue_type_for' do
    let(:input_issue_type) { :incident }
    let(:issue) { build(:issue, input_issue_type) }

    subject(:issue_type) { helper.issue_type_for(issue) }

    context 'when issue is nil' do
      let(:issue) { nil }

      it { is_expected.to be_nil }
    end

    context 'when issue_type_uses_work_item_types_table feature flag is enabled' do
      it 'gets type from the work_item_types table' do
        expect(issue).to receive(:work_item_type).and_call_original
        expect(issue_type).to eq(input_issue_type.to_s)
      end
    end

    context 'when issue_type_uses_work_item_types_table feature flag is disabled' do
      before do
        stub_feature_flags(issue_type_uses_work_item_types_table: false)
      end

      it 'gets type from the issue_type column' do
        expect(issue).to receive(:issue_type).and_call_original
        expect(issue_type).to eq(input_issue_type.to_s)
      end
    end
  end
end
