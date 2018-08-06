require 'spec_helper'
require Rails.root.join('ee', 'db', 'post_migrate', '20180713171825_update_epic_dates_from_milestones.rb')

describe UpdateEpicDatesFromMilestones, :migration do
  let(:migration) { described_class.new }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:epic_issues) { table(:epic_issues) }
  let(:milestones) { table(:milestones) }

  describe '#up' do
    before do
      user = users.create!(email: 'test@example.com', projects_limit: 100, username: 'test')
      namespaces.create(id: 1, name: 'gitlab-org', path: 'gitlab-org')
      projects.create!(id: 1, namespace_id: 1, name: 'gitlab1', path: 'gitlab1')

      epics.create!(id: 1, iid: 1, group_id: 1, title: 'epic with start and due dates', title_html: '', author_id: user.id)
      epics.create!(id: 2, iid: 2, group_id: 1, title: 'epic with only due date', title_html: '', author_id: user.id)
      epics.create!(id: 3, iid: 3, group_id: 1, title: 'epic without milestone', title_html: '', author_id: user.id)

      milestones.create!(
        id: 1,
        iid: 1,
        project_id: 1,
        title: 'milestone-1',
        start_date: Date.new(2000, 1, 1),
        due_date: Date.new(2000, 1, 10)
      )
      milestones.create!(
        id: 2,
        iid: 2,
        project_id: 1,
        title: 'milestone-2',
        due_date: Date.new(2000, 1, 30)
      )

      issues.create!(id: 1, iid: 1, project_id: 1, milestone_id: 1, title: 'issue-1')
      issues.create!(id: 2, iid: 2, project_id: 1, milestone_id: 2, title: 'issue-2')
      issues.create!(id: 3, iid: 3, project_id: 1, milestone_id: 2, title: 'issue-2')

      epic_issues.create!(epic_id: 1, issue_id: 1)
      epic_issues.create!(epic_id: 1, issue_id: 2)
      epic_issues.create!(epic_id: 2, issue_id: 3)
    end

    it 'updates dates milestone ids' do
      migration.up

      expect(Epic.find(1)).to have_attributes(
        start_date: Date.new(2000, 1, 1),
        start_date_sourcing_milestone_id: 1,
        due_date: Date.new(2000, 1, 30),
        due_date_sourcing_milestone_id: 2
      )
      expect(Epic.find(2)).to have_attributes(
        start_date: nil,
        start_date_sourcing_milestone_id: nil,
        due_date: Date.new(2000, 1, 30),
        due_date_sourcing_milestone_id: 2
      )
      expect(Epic.find(3)).to have_attributes(
        start_date: nil,
        start_date_sourcing_milestone_id: nil,
        due_date: nil,
        due_date_sourcing_milestone_id: nil
      )
    end
  end
end
