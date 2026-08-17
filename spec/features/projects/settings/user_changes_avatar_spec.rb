# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User changes avatar', feature_category: :groups_and_projects do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'saves the new avatar', :js do
    expect(project.reload.avatar.url).to be_nil

    save_avatar(project)

    expect(page).to have_testid('alert-info')
    expect(project.reload.avatar.url).to eq "/uploads/-/system/project/avatar/#{project.id}/banana_sample.gif"
  end

  context 'with an avatar already set' do
    before do
      save_avatar(project)
    end

    it 'is possible to remove the avatar', :js do
      visit edit_project_path(project)

      within_testid('general-settings-form') do
        click_button 'Remove avatar'
        click_button 'Save changes'
      end

      expect(page).to have_testid('alert-info')
      expect(page).not_to have_button('Remove avatar')
      expect(project.reload.avatar.url).to be_nil
    end
  end

  def save_avatar(project)
    visit edit_project_path(project)

    within_testid('general-settings-form') do
      attach_file(
        'project[avatar]',
        File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif'),
        make_visible: true
      )

      click_button 'Save changes'
    end
  end
end
