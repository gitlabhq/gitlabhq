require 'spec_helper'

describe QuickActions::InterpretService do
  let(:user) { create(:user) }
  let(:developer) { create(:user) }
  let(:developer2) { create(:user) }
  let(:developer3) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:service) { described_class.new(project, developer) }

  before do
    stub_licensed_features(multiple_issue_assignees: true)

    project.add_developer(developer)
  end

  describe '#execute' do
    context 'assign command' do
      let(:content) { "/assign @#{developer.username}" }

      context 'Issue' do
        it 'fetches assignees and populates them if content contains /assign' do
          issue.assignees << user

          _, updates = service.execute(content, issue)

          expect(updates[:assignee_ids]).to match_array([developer.id, user.id])
        end

        context 'assign command with multiple assignees' do
          let(:content) { "/assign @#{developer.username} @#{developer2.username}" }

          before do
            project.add_developer(developer2)
          end

          it 'fetches assignee and populates assignee_ids if content contains /assign' do
            _, updates = service.execute(content, issue)

            expect(updates[:assignee_ids]).to match_array([developer.id, developer2.id])
          end
        end
      end
    end

    context 'unassign command' do
      let(:content) { '/unassign' }

      context 'Issue' do
        it 'unassigns user if content contains /unassign @user' do
          issue.update(assignee_ids: [developer.id, developer2.id])

          _, updates = service.execute("/unassign @#{developer2.username}", issue)

          expect(updates).to eq(assignee_ids: [developer.id])
        end

        it 'unassigns both users if content contains /unassign @user @user1' do
          user = create(:user)

          issue.update(assignee_ids: [developer.id, developer2.id, user.id])

          _, updates = service.execute("/unassign @#{developer2.username} @#{developer.username}", issue)

          expect(updates).to eq(assignee_ids: [user.id])
        end

        it 'unassigns all the users if content contains /unassign' do
          issue.update(assignee_ids: [developer.id, developer2.id])

          _, updates = service.execute('/unassign', issue)

          expect(updates[:assignee_ids]).to be_empty
        end
      end
    end

    context 'reassign command' do
      let(:content) { "/reassign @#{user.username}" }

      context 'Merge Request' do
        let(:merge_request) { create(:merge_request, source_project: project) }

        it 'does not recognize /reassign @user' do
          _, updates = service.execute(content, merge_request)

          expect(updates).to be_empty
        end
      end

      context 'Issue' do
        let(:content) { "/reassign @#{user.username}" }

        before do
          issue.update(assignee_ids: [developer.id])
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
          _, updates = service.execute("/reassign @#{user.username}", issue)

          expect(updates).to eq(assignee_ids: [user.id])
        end
      end
    end
  end

  describe '#explain' do
    describe 'unassign command' do
      let(:content) { '/unassign' }
      let(:issue) { create(:issue, project: project, assignees: [developer, developer2]) }

      it "includes all assignees' references" do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignees @#{developer.username} and @#{developer2.username}."])
      end
    end

    describe 'unassign command with assignee references' do
      let(:content) { "/unassign @#{developer.username} @#{developer3.username}" }
      let(:issue) { create(:issue, project: project, assignees: [developer, developer2, developer3]) }

      it 'includes only selected assignee references' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignees @#{developer.username} and @#{developer3.username}."])
      end
    end

    describe 'unassign command with non-existent assignee reference' do
      let(:content) { "/unassign @#{developer.username} @#{developer3.username}" }
      let(:issue) { create(:issue, project: project, assignees: [developer, developer2]) }

      it 'ignores non-existent assignee references' do
        _, explanations = service.explain(content, issue)

        expect(explanations).to eq(["Removes assignee @#{developer.username}."])
      end
    end
  end
end
