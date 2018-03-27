require 'spec_helper'

feature 'Master creates tag' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'from tag list' do
    before do
      visit project_tags_path(project)
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
        project_tag_path(project, 'v3.0'))
      expect(page).to have_content 'v3.0'
      page.within 'pre.wrap' do
        expect(page).to have_content "Awesome tag message\n\n- hello\n- world"
      end
    end

    scenario 'with multiline release notes parses the release note as Markdown' do
      create_tag_in_form(tag: 'v4.0', ref: 'master', desc: "Awesome release notes\n\n- hello\n- world")

      expect(current_path).to eq(
        project_tag_path(project, 'v4.0'))
      expect(page).to have_content 'v4.0'
      page.within '.description' do
        expect(page).to have_content 'Awesome release notes'
        expect(page).to have_selector('ul li', count: 2)
      end
    end

    scenario 'opens dropdown for ref', :js do
      click_link 'New tag'
      ref_row = find('.form-group:nth-of-type(2) .col-sm-10')
      page.within ref_row do
        ref_input = find('[name="ref"]', visible: false)
        expect(ref_input.value).to eq 'master'
        expect(find('.dropdown-toggle-text')).to have_content 'master'

        find('.js-branch-select').click

        expect(find('.dropdown-menu')).to have_content 'empty-branch'
      end
    end
  end

  context 'from new tag page' do
    before do
      visit new_project_tag_path(project)
    end

    it 'description has autocomplete', :js do
      find('#release_description').native.send_keys('')
      fill_in 'release_description', with: '@'

      expect(page).to have_selector('.atwho-view')
    end
  end

  def create_tag_in_form(tag:, ref:, message: nil, desc: nil)
    click_link 'New tag'
    fill_in 'tag_name', with: tag
    find('#ref', visible: false).set(ref)
    fill_in 'message', with: message unless message.nil?
    fill_in 'release_description', with: desc unless desc.nil?
    click_button 'Create tag'
  end
end
