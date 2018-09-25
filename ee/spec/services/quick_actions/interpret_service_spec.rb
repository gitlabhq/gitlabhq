require 'spec_helper'

describe QuickActions::InterpretService do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:service) { described_class.new(project, current_user) }

  before do
    stub_licensed_features(multiple_issue_assignees: true)

    project.add_developer(current_user)
  end

  describe '#execute' do
    context 'assign command' do
      context 'Issue' do
        it 'fetches assignees and populates them if content contains /assign' do
          issue.update(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/unassign @#{user2.username}\n/assign @#{user3.username}", issue)

          expect(updates[:assignee_ids]).to match_array([user.id, user3.id])
        end

        context 'assign command with multiple assignees' do
          it 'fetches assignee and populates assignee_ids if content contains /assign' do
            issue.update(assignee_ids: [user.id])

            _, updates = service.execute("/unassign @#{user.username}\n/assign @#{user2.username} @#{user3.username}", issue)

            expect(updates[:assignee_ids]).to match_array([user2.id, user3.id])
          end
        end
      end
    end

    context 'unassign command' do
      let(:content) { '/unassign' }

      context 'Issue' do
        it 'unassigns user if content contains /unassign @user' do
          issue.update(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/assign @#{user3.username}\n/unassign @#{user2.username}", issue)

          expect(updates[:assignee_ids]).to match_array([user.id, user3.id])
        end

        it 'unassigns both users if content contains /unassign @user @user1' do
          issue.update(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/assign @#{user3.username}\n/unassign @#{user2.username} @#{user3.username}", issue)

          expect(updates[:assignee_ids]).to match_array([user.id])
        end

        it 'unassigns all the users if content contains /unassign' do
          issue.update(assignee_ids: [user.id, user2.id])

          _, updates = service.execute("/assign @#{user3.username}\n/unassign", issue)

          expect(updates[:assignee_ids]).to be_empty
        end
      end
    end

    context 'reassign command' do
      let(:content) { "/reassign @#{current_user.username}" }

      context 'Merge Request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        it 'does not recognize /reassign @user' do
          _, updates = service.execute(content, merge_request)

          expect(updates).to be_empty
        end
      end

      context 'Issue' do
        let(:content) { "/reassign @#{current_user.username}" }

        before do
          issue.update(assignee_ids: [user.id])
        end

        context 'unlicensed' do
          before do
            stub_licensed_features(multiple_issue_assignees: false)
          end

          it 'does not recognize /reassign @user' do
            _, updates = service.execute(content, issue)

            expect(updates).to be_empty
          end
        end

        it 'reassigns user if content contains /reassign @user' do
          _, updates = service.execute("/reassign @#{current_user.username}", issue)

          expect(updates[:assignee_ids]).to match_array([current_user.id])
        end
      end
    end

    context 'epic command' do
      let(:epic) { create(:epic, group: group)}
      let(:content) { "/epic #{epic.to_reference(project)}" }

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'assigns an issue to an epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to eq(epic: epic)
        end

        context 'when an issue belongs to a project without group' do
          let(:user_project) { create(:project) }
          let(:issue)        { create(:issue, project: user_project) }

          before do
            user_project.add_developer(user)
          end

          it 'does not assign an issue to an epic' do
            _, updates = service.execute(content, issue)

            expect(updates).to be_empty
          end
        end
      end

      context 'when epics are disabled' do
        it 'does not recognize /epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to be_empty
        end
      end
    end

    context 'remove_epic command' do
      let(:epic) { create(:epic, group: group)}
      let(:content) { "/remove_epic #{epic.to_reference(project)}" }

      before do
        issue.update!(epic: epic)
      end

      context 'when epics are disabled' do
        it 'does not recognize /remove_epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to be_empty
        end
      end

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'unassigns an issue from an epic' do
          _, updates = service.execute(content, issue)

          expect(updates).to eq(epic: nil)
        end
      end
    end
  end

  describe '#explain' do
    describe 'unassign command' do
      let(:content) { '/unassign' }
      let(:issue) { create(:issue, project: project, assignees: [user, user2]) }

      it "includes all assignees' references" do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignees @#{user.username} and @#{user2.username}."])
      end
    end

    describe 'unassign command with assignee references' do
      let(:content) { "/unassign @#{user.username} @#{user3.username}" }
      let(:issue) { create(:issue, project: project, assignees: [user, user2, user3]) }

      it 'includes only selected assignee references' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignees @#{user.username} and @#{user3.username}."])
      end
    end

    describe 'unassign command with non-existent assignee reference' do
      let(:content) { "/unassign @#{user.username} @#{user3.username}" }
      let(:issue) { create(:issue, project: project, assignees: [user, user2]) }

      it 'ignores non-existent assignee references' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignee @#{user.username}."])
      end
    end
  end
end
