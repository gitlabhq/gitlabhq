module SharedIssuable
  include Spinach::DSL

  def edit_issuable
    find('.js-issuable-edit', visible: true).click
  end

  step 'I leave a comment referencing issue "Community issue"' do
    leave_reference_comment(
      issuable: Issue.find_by(title: 'Community issue'),
      from_project_name: 'Enterprise'
    )
  end

  step 'I click link "Edit" for the merge request' do
    edit_issuable
  end

  step 'I sort the list by "Least popular"' do
    find('button.dropdown-toggle').click

    page.within('.content ul.dropdown-menu.dropdown-menu-align-right li') do
      click_link 'Least popular'
    end
  end

  step 'I click link "Next" in the sidebar' do
    page.within '.issuable-sidebar' do
      click_link 'Next'
    end
  end

  def create_issuable_for_project(project_name:, title:, type: :issue)
    project = Project.find_by(name: project_name)

    attrs = {
      title: title,
      author: project.users.first,
      description: '# Description header'
    }

    case type
    when :issue
      attrs[:project] = project
    when :merge_request
      attrs.merge!(
        source_project: project,
        target_project: project,
        source_branch: 'fix',
        target_branch: 'master'
      )
    end

    create(type, attrs)
  end

  def leave_reference_comment(issuable:, from_project_name:)
    project = Project.find_by(name: from_project_name)

    page.within('.js-main-target-form') do
      fill_in 'note[note]', with: "##{issuable.to_reference(project)}"
      click_button 'Comment'
    end
  end

  def visible_note(issuable:, from_project_name:, user_name:)
    project = Project.find_by(name: from_project_name)

    expect(page).to have_content(user_name)
    expect(page).to have_content("mentioned in #{issuable.class.to_s.titleize.downcase} #{issuable.to_reference(project)}")
  end

  def expect_sidebar_content(content)
    page.within '.issuable-sidebar' do
      expect(page).to have_content content
    end
  end
end
