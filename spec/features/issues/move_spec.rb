require 'rails_helper'

feature 'issue move to another project' do
  let(:user) { create(:user) }
  let(:old_project) { create(:project) }
  let(:text) { 'Some issue description' }

  let(:issue) do
    create(:issue, description: text, project: old_project, author: user)
  end

  background { login_as(user) }

  context 'user does not have permission to move issue' do
    background do
      old_project.team << [user, :guest]

      edit_issue(issue)
    end

    scenario 'moving issue to another project not allowed' do
      expect(page).to have_no_selector('#move_to_project_id')
    end
  end

  context 'user has permission to move issue' do
    let!(:mr) { create(:merge_request, source_project: old_project) }
    let(:new_project) { create(:project) }
    let(:new_project_search) { create(:project) }
    let(:text) { "Text with #{mr.to_reference}" }
    let(:cross_reference) { old_project.to_reference }

    background do
      old_project.team << [user, :reporter]
      new_project.team << [user, :reporter]

      edit_issue(issue)
    end

    scenario 'moving issue to another project' do
      first('#move_to_project_id', visible: false).set(new_project.id)
      click_button('Save changes')

      expect(current_url).to include project_path(new_project)

      expect(page).to have_content("Text with #{cross_reference}#{mr.to_reference}")
      expect(page).to have_content("moved from #{cross_reference}#{issue.to_reference}")
      expect(page).to have_content(issue.title)
    end

    scenario 'searching project dropdown', js: true do
      new_project_search.team << [user, :reporter]

      page.within '.js-move-dropdown' do
        first('.select2-choice').click
      end

      fill_in('s2id_autogen1_search', with: new_project_search.name)

      page.within '.select2-drop' do
        expect(page).to have_content(new_project_search.name)
        expect(page).not_to have_content(new_project.name)
      end
    end

    context 'user does not have permission to move the issue to a project', js: true do
      let!(:private_project) { create(:project, :private) }
      let(:another_project) { create(:project) }
      background { another_project.team << [user, :guest] }

      scenario 'browsing projects in projects select' do
        click_link 'Select project'

        page.within '.select2-results' do
          expect(page).to have_content 'No project'
          expect(page).to have_content new_project.name_with_namespace
        end
      end
    end

    context 'issue has been already moved' do
      let(:new_issue) { create(:issue, project: new_project) }
      let(:issue) do
        create(:issue, project: old_project, author: user, moved_to: new_issue)
      end

      scenario 'user wants to move issue that has already been moved' do
        expect(page).to have_no_selector('#move_to_project_id')
      end
    end
  end

  def edit_issue(issue)
    visit issue_path(issue)
    page.within('.issuable-actions') { first(:link, 'Edit').click }
  end

  def issue_path(issue)
    namespace_project_issue_path(issue.project.namespace, issue.project, issue)
  end

  def project_path(project)
    namespace_project_path(new_project.namespace, new_project)
  end
end
