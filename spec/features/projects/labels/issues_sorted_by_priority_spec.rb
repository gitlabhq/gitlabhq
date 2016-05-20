require 'spec_helper'

feature 'Issue prioritization', feature: true do

  let(:user)    { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }

  # According to https://gitlab.com/gitlab-org/gitlab-ce/issues/14189#note_4360653
  context 'when assigned with prioritized labels' do
    scenario 'Are sorted properly' do
      login_as user

      label_1 = create(:label, title: 'label_1', priority: 1)
      label_2 = create(:label, title: 'label_2', priority: 2)
      label_3 = create(:label, title: 'label_3', priority: 3)
      label_4 = create(:label, title: 'label_4', priority: 4)
      label_5 = create(:label, title: 'label_5') # no priority

      project.labels << label_1
      project.labels << label_2
      project.labels << label_3
      project.labels << label_4
      project.labels << label_5

      issue_1 = create(:issue, title: 'issue_1', project: project)
      issue_2 = create(:issue, title: 'issue_2', project: project)
      issue_3 = create(:issue, title: 'issue_3', project: project)
      issue_4 = create(:issue, title: 'issue_4', project: project)
      issue_5 = create(:issue, title: 'issue_5', project: project)
      issue_6 = create(:issue, title: 'issue_6', project: project)
      issue_7 = create(:issue, title: 'issue_7', project: project)
      issue_8 = create(:issue, title: 'issue_8', project: project)

      # Assign labels to issues disorderly
      issue_4.labels << label_1
      issue_3.labels << label_2
      issue_5.labels << label_3
      issue_2.labels << label_4
      issue_1.labels << label_5
      issue_6.labels << label_5
      issue_7.labels << label_5
      issue_8.labels << label_5

      visit namespace_project_issues_path(project.namespace, project, sort: 'priority')

      # Ensure we are indicating that issues are sorted by priority
      expect(page).to have_selector('.dropdown-toggle', text: 'Priority')

      page.within('.issues-list') do
        expect(find('> li:nth-of-type(1)')).to have_content('issue_4')
        expect(find('> li:nth-of-type(2)')).to have_content('issue_3')
        expect(find('> li:nth-of-type(3)')).to have_content('issue_5')
        expect(find('> li:nth-of-type(4)')).to have_content('issue_2')

        # the rest should be at the bottom
        expect(find('> li:nth-of-type(5)')).to have_content('issue_7')
        expect(find('> li:nth-of-type(6)')).to have_content('issue_8')
        expect(find('> li:nth-of-type(7)')).to have_content('issue_1')
        expect(find('> li:nth-of-type(8)')).to have_content('issue_6')
      end
    end
  end
end
