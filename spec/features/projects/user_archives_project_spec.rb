require 'spec_helper'

describe 'User archives a project' do
  let(:user) { create(:user) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  context 'when a project is archived' do
    let(:project) { create(:project, :archived, namespace: user.namespace) }

    before do
      visit(edit_project_path(project))
    end

    it 'unarchives a project' do
      expect(page).to have_content('Unarchive project')

      click_link('Unarchive')

      expect(page).not_to have_content('Archived project')
    end
  end

  context 'when a project is unarchived' do
    let(:project) { create(:project, :repository, namespace: user.namespace) }

    before do
      visit(edit_project_path(project))
    end

    it 'archives a project' do
      expect(page).to have_content('Archive project')

      click_link('Archive')

      expect(page).to have_content('Archived')
    end
  end
end
