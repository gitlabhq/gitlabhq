# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User archives a project', feature_category: :groups_and_projects do
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit edit_project_path(project)
  end

  context 'when a project is archived' do
    let(:project) { create(:project, :archived, namespace: user.namespace) }

    it 'unarchives a project' do
      expect(page).to have_content('Unarchive project')

      click_link('Unarchive')

      expect(page).not_to have_content('This is an archived project.')
    end
  end

  context 'when a project is unarchived' do
    let(:project) { create(:project, :repository, namespace: user.namespace) }

    it 'archives a project' do
      expect(page).to have_content('Archive project')

      click_link('Archive')

      expect(page).to have_content('This is an archived project.')
    end
  end
end
