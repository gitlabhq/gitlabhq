require 'rails_helper'

describe 'New/edit issue', feature: true, js: true do
  let!(:project)   { create(:project) }
  let!(:user)      { create(:user)}
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }
  let!(:issue)     { create(:issue, project: project, assignee: user, milestone: milestone) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  context 'new issue' do
    before do
      visit new_namespace_project_issue_path(project.namespace, project)
    end

    it 'should allow user to create new issue' do
      fill_in 'issue_title', with: 'title'
      fill_in 'issue_description', with: 'title'

      click_button 'Assignee'
      page.within '.dropdown-menu-user' do
        click_link user.name
      end
      expect(find('input[name="issue[assignee_id]"]', visible: false).value).to match(user.id.to_s)
      page.within '.js-assignee-search' do
        expect(page).to have_content user.name
      end

      click_button 'Milestone'
      page.within '.issue-milestone' do
        click_link milestone.title
      end
      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      page.within '.js-milestone-select' do
        expect(page).to have_content milestone.title
      end

      click_button 'Labels'
      page.within '.dropdown-menu-labels' do
        click_link label.title
        click_link label2.title
      end
      page.within '.js-label-select' do
        expect(page).to have_content label.title
      end
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

      click_button 'Submit issue'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content user.name
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end
    end
  end

  context 'edit issue' do
    before do
      visit edit_namespace_project_issue_path(project.namespace, project, issue)
    end

    it 'should allow user to update issue' do
      expect(find('input[name="issue[assignee_id]"]', visible: false).value).to match(user.id.to_s)
      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)

      page.within '.js-user-search' do
        expect(page).to have_content user.name
      end

      page.within '.js-milestone-select' do
        expect(page).to have_content milestone.title
      end

      click_button 'Labels'
      page.within '.dropdown-menu-labels' do
        click_link label.title
        click_link label2.title
      end
      page.within '.js-label-select' do
        expect(page).to have_content label.title
      end
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[1].value).to match(label.id.to_s)
      expect(page.all('input[name="issue[label_ids][]"]', visible: false)[2].value).to match(label2.id.to_s)

      click_button 'Save changes'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_content user.name
        end

        page.within '.milestone' do
          expect(page).to have_content milestone.title
        end

        page.within '.labels' do
          expect(page).to have_content label.title
          expect(page).to have_content label2.title
        end
      end
    end
  end
end
