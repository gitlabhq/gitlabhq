require 'spec_helper'

describe EpicIssues::ListService do
  let(:user) { create :user }
  let(:group) { create(:group, :private) }
  let(:project) { create(:project_empty_repo, group: group) }
  let(:other_project) { create(:project_empty_repo, group: group) }
  let(:epic) { create(:epic, group: group) }

  let(:issue1) { create :issue, project: project }
  let(:issue2) { create :issue, project: project }
  let(:issue3) { create :issue, project: other_project }

  let!(:epic_issue1) { create(:epic_issue, issue: issue1, epic: epic) }
  let!(:epic_issue2) { create(:epic_issue, issue: issue2, epic: epic) }
  let!(:epic_issue3) { create(:epic_issue, issue: issue3, epic: epic) }

  describe '#execute' do
    subject { described_class.new(epic, user).execute }

    context 'when epics feature is disabled' do
      it 'returns an empty array' do
        group.add_developer(user)

        expect(subject).to be_empty
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'owner can see all issues and destroy their associations' do
        before do
          group.add_developer(user)
        end

        it 'returns related issues JSON' do
          expected_result = [
            {
              id: issue1.id,
              title: issue1.title,
              state: issue1.state,
              reference: issue1.to_reference(full: true),
              path: "/#{project.full_path}/issues/#{issue1.iid}",
              destroy_relation_path: "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issue1.id}"
            },
            {
              id: issue2.id,
              title: issue2.title,
              state: issue2.state,
              reference: issue2.to_reference(full: true),
              path: "/#{project.full_path}/issues/#{issue2.iid}",
              destroy_relation_path: "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issue2.id}"
            },
            {
              id: issue3.id,
              title: issue3.title,
              state: issue3.state,
              reference: issue3.to_reference(full: true),
              path: "/#{other_project.full_path}/issues/#{issue3.iid}",
              destroy_relation_path: "/groups/#{group.full_path}/-/epics/#{epic.iid}/issues/#{epic_issue3.id}"
            }
          ]
          expect(subject).to match_array(expected_result)
        end
      end

      context 'user can see only some issues' do
        before do
          project.add_developer(user)
        end

        it 'returns related issues JSON' do
          expected_result = [
            {
              id: issue1.id,
              title: issue1.title,
              state: issue1.state,
              reference: issue1.to_reference(full: true),
              path: "/#{project.full_path}/issues/#{issue1.iid}",
              destroy_relation_path: nil
            },
            {
              id: issue2.id,
              title: issue2.title,
              state: issue2.state,
              reference: issue2.to_reference(full: true),
              path: "/#{project.full_path}/issues/#{issue2.iid}",
              destroy_relation_path: nil
            }
          ]

          expect(subject).to match_array(expected_result)
        end
      end
    end
  end
end
