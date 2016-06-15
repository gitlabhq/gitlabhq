require 'rails_helper'

feature 'Issue Sidebar', feature: true do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let!(:user) { create(:user)}

  before do
    create(:label, project: project, title: 'bug')
    login_as(user)
  end

  context 'as a allowed user' do
    before do
      project.team << [user, :developer]
      visit_issue(project, issue)
    end

    describe 'when clicking on edit labels', js: true do
      it 'dropdown has an option to create a new label' do
        find('.block.labels .edit-link').click

        page.within('.block.labels') do
          expect(page).to have_content 'Create new'
        end
      end
    end

    context 'creating a new label', js: true do
      it 'option to crate a new label is present' do
        page.within('.block.labels') do
          find('.edit-link').click

          expect(page).to have_content 'Create new'
        end
      end

      it 'dropdown switches to "create label" section' do
        page.within('.block.labels') do
          find('.edit-link').click
          click_link 'Create new'

          expect(page).to have_content 'Create new label'
        end
      end

      it 'new label is added' do
        page.within('.block.labels') do
          find('.edit-link').click
          sleep 1
          click_link 'Create new'

          fill_in 'new_label_name', with: 'wontfix'
          page.find(".suggest-colors a", match: :first).click
          click_button 'Create'

          page.within('.dropdown-page-one') do
            expect(page).to have_content 'wontfix'
          end
        end
      end
    end
  end

  context 'as a guest' do
    before do
      project.team << [user, :guest]
      visit_issue(project, issue)
    end

    it 'does not have a option to edit labels' do
      expect(page).not_to have_selector('.block.labels .edit-link')
    end
  end

  context 'updating weight', js: true do
    before do
      project.team << [user, :master]
      visit_issue(project, issue)
    end

    it 'should update weight in sidebar to 1' do
      page.within '.weight' do
        click_link 'Edit'
        click_link '1'

        page.within '.value' do
          expect(page).to have_content '1'
        end
      end
    end

    it 'should update weight in sidebar to no weight' do
      page.within '.weight' do
        click_link 'Edit'
        click_link 'No Weight'

        page.within '.value' do
          expect(page).to have_content 'None'
        end
      end
    end
  end

  def visit_issue(project, issue)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end
end
