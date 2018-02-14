require 'spec_helper'

describe Issue do
  using RSpec::Parameterized::TableSyntax

  describe '#allows_multiple_assignees?' do
    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: false)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_falsey
    end

    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: true)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_truthy
    end
  end

  describe '#weight' do
    where(:license_value, :database_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:issue) { build(:issue, weight: database_value) }

      subject { issue.weight }

      before do
        stub_licensed_features(issue_weights: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end
end
