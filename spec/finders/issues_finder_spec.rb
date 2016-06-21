require 'spec_helper'

describe IssuesFinder do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:project1) { create(:empty_project) }
  let(:project2) { create(:empty_project) }
  let(:milestone) { create(:milestone, project: project1) }
  let(:label) { create(:label, project: project2) }
  let(:issue1) { create(:issue, author: user, assignee: user, project: project1, milestone: milestone) }
  let(:issue2) { create(:issue, author: user, assignee: user, project: project2) }
  let(:issue3) { create(:issue, author: user2, assignee: user2, project: project2) }
  let!(:label_link) { create(:label_link, label: label, target: issue2) }

  before do
    project1.team << [user, :master]
    project2.team << [user, :developer]
    project2.team << [user2, :developer]

    issue1
    issue2
    issue3
  end

  describe '#execute' do
    let(:search_user) { user }
    let(:params) { {} }
    let(:issues) { IssuesFinder.new(search_user, params.merge(scope: scope, state: 'opened')).execute }

    context 'scope: all' do
      let(:scope) { 'all' }

      it 'returns all issues' do
        expect(issues).to contain_exactly(issue1, issue2, issue3)
      end

      context 'sort by issues with no weight' do
        let(:params) { { weight: Issue::WEIGHT_NONE } }

        it 'returns all issues' do
          expect(issues).to contain_exactly(issue1, issue2, issue3)
        end
      end

      context 'sort by issues with any weight' do
        let(:params) { { weight: Issue::WEIGHT_ANY } }

        it 'returns all issues' do
          expect(issues).to be_empty
        end
      end

      context 'filtering by assignee ID' do
        let(:params) { { assignee_id: user.id } }

        it 'returns issues assigned to that user' do
          expect(issues).to contain_exactly(issue1, issue2)
        end
      end

      context 'filtering by author ID' do
        let(:params) { { author_id: user2.id } }

        it 'returns issues created by that user' do
          expect(issues).to contain_exactly(issue3)
        end
      end

      context 'filtering by milestone' do
        let(:params) { { milestone_title: milestone.title } }

        it 'returns issues assigned to that milestone' do
          expect(issues).to contain_exactly(issue1)
        end
      end

      context 'filtering by no milestone' do
        let(:params) { { milestone_title: Milestone::None.title } }

        it 'returns issues with no milestone' do
          expect(issues).to contain_exactly(issue2, issue3)
        end
      end

      context 'filtering by upcoming milestone' do
        let(:params) { { milestone_title: Milestone::Upcoming.name } }

        let(:project_no_upcoming_milestones) { create(:empty_project, :public) }
        let(:project_next_1_1) { create(:empty_project, :public) }
        let(:project_next_8_8) { create(:empty_project, :public) }

        let(:yesterday) { Date.today - 1.day }
        let(:tomorrow) { Date.today + 1.day }
        let(:two_days_from_now) { Date.today + 2.days }
        let(:ten_days_from_now) { Date.today + 10.days }

        let(:milestones) do
          [
            create(:milestone, :closed, project: project_no_upcoming_milestones),
            create(:milestone, project: project_next_1_1, title: '1.1', due_date: two_days_from_now),
            create(:milestone, project: project_next_1_1, title: '8.8', due_date: ten_days_from_now),
            create(:milestone, project: project_next_8_8, title: '1.1', due_date: yesterday),
            create(:milestone, project: project_next_8_8, title: '8.8', due_date: tomorrow)
          ]
        end

        before do
          milestones.each do |milestone|
            create(:issue, project: milestone.project, milestone: milestone, author: user, assignee: user)
          end
        end

        it 'returns issues in the upcoming milestone for each project' do
          expect(issues.map { |issue| issue.milestone.title }).to contain_exactly('1.1', '8.8')
          expect(issues.map { |issue| issue.milestone.due_date }).to contain_exactly(tomorrow, two_days_from_now)
        end
      end

      context 'filtering by label' do
        let(:params) { { label_name: label.title } }

        it 'returns issues with that label' do
          expect(issues).to contain_exactly(issue2)
        end
      end

      context 'filtering by multiple labels' do
        let(:params) { { label_name: [label.title, label2.title].join(',') } }
        let(:label2) { create(:label, project: project2) }

        before { create(:label_link, label: label2, target: issue2) }

        it 'returns the unique issues with any of those labels' do
          expect(issues).to contain_exactly(issue2)
        end
      end

      context 'filtering by no label' do
        let(:params) { { label_name: Label::None.title } }

        it 'returns issues with no labels' do
          expect(issues).to contain_exactly(issue1, issue3)
        end
      end

      context 'when the user is unauthorized' do
        let(:search_user) { nil }

        it 'returns no results' do
          expect(issues).to be_empty
        end
      end

      context 'when the user can see some, but not all, issues' do
        let(:search_user) { user2 }

        it 'returns only issues they can see' do
          expect(issues).to contain_exactly(issue2, issue3)
        end
      end
    end

    context 'personal scope' do
      let(:scope) { 'assigned-to-me' }

      it 'returns issue assigned to the user' do
        expect(issues).to contain_exactly(issue1, issue2)
      end

      context 'filtering by project' do
        let(:params) { { project_id: project1.id } }

        it 'returns issues assigned to the user in that project' do
          expect(issues).to contain_exactly(issue1)
        end
      end
    end
  end
end
