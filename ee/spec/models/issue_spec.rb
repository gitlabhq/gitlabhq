require 'spec_helper'

describe Issue do
  using RSpec::Parameterized::TableSyntax
  include ExternalAuthorizationServiceHelpers

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

  describe '#sort' do
    let(:project) { create(:project) }

    context "by weight" do
      let!(:issue)  { create(:issue, project: project) }
      let!(:issue2) { create(:issue, weight: 1, project: project) }
      let!(:issue3) { create(:issue, weight: 2, project: project) }
      let!(:issue4) { create(:issue, weight: 3, project: project) }

      it "sorts desc" do
        issues = project.issues.sort('weight_desc')
        expect(issues).to eq([issue4, issue3, issue2, issue])
      end

      it "sorts asc" do
        issues = project.issues.sort('weight_asc')
        expect(issues).to eq([issue2, issue3, issue4, issue])
      end
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

  context 'when an external authentication service' do
    before do
      enable_external_authorization_service_check
    end

    describe '#publicly_visible?' do
      it 'is `false` when an external authorization service is enabled' do
        issue = build(:issue, project: build(:project, :public))

        expect(issue).not_to be_publicly_visible
      end
    end

    describe '#readable_by?' do
      it 'checks the external service to determine if an issue is readable by a user' do
        project = build(:project, :public,
                        external_authorization_classification_label: 'a-label')
        issue = build(:issue, project: project)
        user = build(:user)

        expect(EE::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label') { false }
        expect(issue.readable_by?(user)).to be_falsy
      end

      it 'does not check the external webservice for admins' do
        issue = build(:issue)
        user = build(:admin)

        expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        issue.readable_by?(user)
      end

      it 'does not check the external webservice for auditors' do
        issue = build(:issue)
        user = build(:auditor)

        expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        issue.readable_by?(user)
      end
    end
  end
end
