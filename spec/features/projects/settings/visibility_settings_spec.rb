require 'spec_helper'

feature 'Visibility settings', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace, visibility_level: 20) }

  context 'as owner' do
    before do
      sign_in(user)
      visit edit_project_path(project)
    end

    scenario 'project visibility select is available' do
      visibility_select_container = find('.project-visibility-setting')

      expect(visibility_select_container.find('select').value).to eq project.visibility_level.to_s
      expect(visibility_select_container).to have_content 'The project can be accessed by anyone, regardless of authentication.'
    end

    scenario 'project visibility description updates on change' do
      visibility_select_container = find('.project-visibility-setting')
      visibility_select = visibility_select_container.find('select')
      visibility_select.select('Private')

      expect(visibility_select.value).to eq '0'
      expect(visibility_select_container).to have_content 'Access must be granted explicitly to each user.'
    end
  end

  context 'as master' do
    let(:master_user) { create(:user) }

    before do
      project.add_master(master_user)
      sign_in(master_user)
      visit edit_project_path(project)
    end

    scenario 'project visibility is locked' do
      visibility_select_container = find('.project-visibility-setting')

      expect(visibility_select_container).to have_selector 'select[name="project[visibility_level]"]:disabled'
      expect(visibility_select_container).to have_content 'The project can be accessed by anyone, regardless of authentication.'
    end
  end
end
