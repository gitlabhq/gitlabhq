require 'rails_helper'

feature 'Issue Sidebar' do
  include MobileHelpers

  let(:group) { create(:group, :nested) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:issue) { create(:issue, project: project) }
  let!(:user) { create(:user)}
  let!(:label) { create(:label, project: project, title: 'bug') }
  let!(:xss_label) { create(:label, project: project, title: '&lt;script&gt;alert("xss");&lt;&#x2F;script&gt;') }

  before do
    sign_in(user)
  end

  context 'assignee', :js do
    let(:user2) { create(:user) }
    let(:issue2) { create(:issue, project: project, author: user2) }

    before do
      project.add_developer(user)
      visit_issue(project, issue2)

      find('.block.assignee .edit-link').click

      wait_for_requests
    end

    it 'shows author in assignee dropdown' do
      page.within '.dropdown-menu-user' do
        expect(page).to have_content(user2.name)
      end
    end

    it 'shows author when filtering assignee dropdown' do
      page.within '.dropdown-menu-user' do
        find('.dropdown-input-field').native.send_keys user2.name
        sleep 1 # Required to wait for end of input delay

        wait_for_requests

        expect(page).to have_content(user2.name)
      end
    end

    it 'assigns yourself' do
      find('.block.assignee .dropdown-menu-toggle').click

      click_button 'assign yourself'

      wait_for_requests

      find('.block.assignee .edit-link').click

      page.within '.dropdown-menu-user' do
        expect(page.find('.dropdown-header')).to be_visible
        expect(page.find('.dropdown-menu-user-link.is-active')).to have_content(user.name)
      end
    end

    it 'keeps your filtered term after filtering and dismissing the dropdown' do
      find('.dropdown-input-field').native.send_keys user2.name

      wait_for_requests

      page.within '.dropdown-menu-user' do
        expect(page).not_to have_content 'Unassigned'
        click_link user2.name
      end

      find('.js-right-sidebar').click
      find('.block.assignee .edit-link').click

      expect(page.all('.dropdown-menu-user li').length).to eq(1)
      expect(find('.dropdown-input-field').value).to eq(user2.name)
    end
  end

  context 'as a allowed user' do
    before do
      project.add_developer(user)
      visit_issue(project, issue)
    end

    context 'sidebar', :js do
      it 'changes size when the screen size is smaller' do
        sidebar_selector = 'aside.right-sidebar.right-sidebar-collapsed'
        # Resize the window
        resize_screen_sm
        # Make sure the sidebar is collapsed
        find(sidebar_selector)
        expect(page).to have_css(sidebar_selector)
        # Once is collapsed let's open the sidebard and reload
        open_issue_sidebar
        refresh
        find(sidebar_selector)
        expect(page).to have_css(sidebar_selector)
        # Restore the window size as it was including the sidebar
        restore_window_size
        open_issue_sidebar
      end

      it 'escapes XSS when viewing issue labels' do
        page.within('.block.labels') do
          find('.edit-link').click

          expect(page).to have_content '<script>alert("xss");</script>'
        end
      end
    end

    context 'editing issue labels', :js do
      before do
        page.within('.block.labels') do
          find('.edit-link').click
        end
      end

      it 'shows option to create a project label' do
        page.within('.block.labels') do
          expect(page).to have_content 'Create project'
        end
      end

      context 'creating a project label', :js do
        before do
          page.within('.block.labels') do
            click_link 'Create project'
          end
        end

        it 'shows dropdown switches to "create label" section' do
          page.within('.block.labels') do
            expect(page).to have_content 'Create project label'
          end
        end

        it 'adds new label' do
          page.within('.block.labels') do
            fill_in 'new_label_name', with: 'wontfix'
            page.find('.suggest-colors a', match: :first).click
            page.find('button', text: 'Create').click

            page.within('.dropdown-page-one') do
              expect(page).to have_content 'wontfix'
            end
          end
        end

        it 'shows error message if label title is taken' do
          page.within('.block.labels') do
            fill_in 'new_label_name', with: label.title
            page.find('.suggest-colors a', match: :first).click
            page.find('button', text: 'Create').click

            page.within('.dropdown-page-two') do
              expect(page).to have_content 'Title has already been taken'
            end
          end
        end
      end
    end

    context 'interacting with collapsed sidebar', :js do
      collapsed_sidebar_selector = 'aside.right-sidebar.right-sidebar-collapsed'
      expanded_sidebar_selector = 'aside.right-sidebar.right-sidebar-expanded'
      confidentiality_sidebar_block = '.block.confidentiality'
      lock_sidebar_block = '.block.lock'
      collapsed_sidebar_block_icon = '.sidebar-collapsed-icon'

      before do
        resize_screen_sm
      end

      it 'confidentiality block expands then collapses sidebar' do
        expect(page).to have_css(collapsed_sidebar_selector)

        page.within(confidentiality_sidebar_block) do
          find(collapsed_sidebar_block_icon).click
        end

        expect(page).to have_css(expanded_sidebar_selector)

        page.within(confidentiality_sidebar_block) do
          page.find('button', text: 'Cancel').click
        end

        expect(page).to have_css(collapsed_sidebar_selector)
      end

      it 'lock block expands then collapses sidebar' do
        expect(page).to have_css(collapsed_sidebar_selector)

        page.within(lock_sidebar_block) do
          find(collapsed_sidebar_block_icon).click
        end

        expect(page).to have_css(expanded_sidebar_selector)

        page.within(lock_sidebar_block) do
          page.find('button', text: 'Cancel').click
        end

        expect(page).to have_css(collapsed_sidebar_selector)
      end
    end
  end

  context 'as a guest' do
    before do
      project.add_guest(user)
      visit_issue(project, issue)
    end

    it 'does not have a option to edit labels' do
      expect(page).not_to have_selector('.block.labels .edit-link')
    end
  end

  context 'updating weight', :js do
    before do
      project.add_master(user)
      visit_issue(project, issue)
    end

    it 'updates weight in sidebar to 1' do
      page.within '.weight' do
        click_link 'Edit'
        click_link '1'

        page.within '.value' do
          expect(page).to have_content '1'
        end
      end
    end

    it 'updates weight in sidebar to no weight' do
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
    visit project_issue_path(project, issue)
  end

  def open_issue_sidebar
    find('aside.right-sidebar.right-sidebar-collapsed .js-sidebar-toggle').click
    find('aside.right-sidebar.right-sidebar-expanded')
  end
end
