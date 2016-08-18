require 'rails_helper'

feature 'Issue Sidebar', feature: true do
  include WaitForAjax

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
      it 'shows dropdown option to create a new label' do
        find('.block.labels .edit-link').click

        page.within('.block.labels') do
          expect(page).to have_content 'Create new'
        end
      end
    end

    context 'creating a new label', js: true do
      it 'shows option to crate a new label is present' do
        page.within('.block.labels') do
          find('.edit-link').click

          expect(page).to have_content 'Create new'
        end
      end

      it 'shows dropdown switches to "create label" section' do
        page.within('.block.labels') do
          find('.edit-link').click
          click_link 'Create new'

          expect(page).to have_content 'Create new label'
        end
      end

      it 'adds new label' do
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

  context 'update labels', js: true do
    before do
      project.team << [user, :developer]
      visit_issue(project, issue)
    end

    context 'more than 5' do
      before do
        create(:label, project: project, title: 'a')
        create(:label, project: project, title: 'b')
        create(:label, project: project, title: 'c')
        create(:label, project: project, title: 'd')
        create(:label, project: project, title: 'e')
        create(:label, project: project, title: 'f')
      end

      it 'should update the tooltip for collapsed sidebar' do
        page.within('.block.labels') do
          find('.edit-link').click

          page.within('.dropdown-menu-labels') do
            click_link 'a'
            click_link 'b'
            click_link 'c'
            click_link 'd'
            click_link 'e'
            click_link 'f'
          end

          find('.edit-link').click
          wait_for_ajax 

          expect(find('.js-sidebar-labels-tooltip', visible: false)['data-original-title']).to eq('a, b, c, d, e, and 1 more')
        end
      end
    end
  end

  def visit_issue(project, issue)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end
end
