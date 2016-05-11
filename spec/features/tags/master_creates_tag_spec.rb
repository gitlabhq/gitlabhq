require 'spec_helper'

feature 'Master creates tag', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    login_with(user)
    visit namespace_project_tags_path(project.namespace, project)
  end

  scenario 'with an invalid name displays an error' do
    create_tag_in_form(tag: 'v 1.0', ref: 'master')

    expect(page).to have_content 'Tag name invalid'
  end

  scenario 'with an invalid reference displays an error' do
    create_tag_in_form(tag: 'v2.0', ref: 'foo')

    expect(page).to have_content 'Target foo is invalid'
  end

  scenario 'that already exists displays an error' do
    create_tag_in_form(tag: 'v1.1.0', ref: 'master')

    expect(page).to have_content 'Tag v1.1.0 already exists'
  end

  scenario 'with multiline message displays the message in a <pre> block' do
    create_tag_in_form(tag: 'v3.0', ref: 'master', message: "Awesome tag message\n\n- hello\n- world")

    expect(current_path).to eq(
      namespace_project_tag_path(project.namespace, project, 'v3.0'))
    expect(page).to have_content 'v3.0'
    page.within 'pre.body' do
      expect(page).to have_content "Awesome tag message\n\n- hello\n- world"
    end
  end

  scenario 'with multiline release notes parses the release note as Markdown' do
    create_tag_in_form(tag: 'v4.0', ref: 'master', desc: "Awesome release notes\n\n- hello\n- world")

    expect(current_path).to eq(
      namespace_project_tag_path(project.namespace, project, 'v4.0'))
    expect(page).to have_content 'v4.0'
    page.within '.description' do
      expect(page).to have_content 'Awesome release notes'
      expect(page).to have_selector('ul li', count: 2)
    end
  end

  def create_tag_in_form(tag:, ref:, message: nil, desc: nil)
    click_link 'New tag'
    fill_in 'tag_name', with: tag
    fill_in 'ref', with: ref
    fill_in 'message', with: message unless message.nil?
    fill_in 'release_description', with: desc unless desc.nil?
    click_button 'Create tag'
  end
end
