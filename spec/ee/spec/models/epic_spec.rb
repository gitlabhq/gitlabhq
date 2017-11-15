require 'spec_helper'

describe Epic do
  describe 'associations' do
    subject { build(:epic) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    subject { create(:epic) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(InternalId) }
  end

  describe '#issues' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :private) }
    let(:project) { create(:project, group: group) }
    let(:project2) { create(:project, group: group) }

    let!(:epic) { create(:epic, group: group) }
    let!(:issue) { create(:issue, project: project)}
    let!(:lone_issue) { create(:issue, project: project)}
    let!(:other_issue) { create(:issue, project: project2)}
    let!(:epic_issues) do
      [
        create(:epic_issue, epic: epic, issue: issue),
        create(:epic_issue, epic: epic, issue: other_issue)
      ]
    end

    let(:result) { epic.issues(user) }

    it 'returns all issues if a user has access to them' do
      group.add_developer(user)

      expect(result.count).to eq(2)
      expect(result.map(&:id)).to match_array([issue.id, other_issue.id])
      expect(result.map(&:epic_issue_id)).to match_array(epic_issues.map(&:id))
    end

    it 'does not return issues user can not see' do
      project.add_developer(user)

      expect(result.count).to eq(1)
      expect(result.map(&:id)).to match_array([issue.id])
      expect(result.map(&:epic_issue_id)).to match_array([epic_issues.first.id])
    end
  end
end
