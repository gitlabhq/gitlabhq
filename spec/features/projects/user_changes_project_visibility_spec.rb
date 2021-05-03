# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User changes public project visibility', :js do
  include ProjectForksHelper

  before do
    fork_project(project, project.owner)

    sign_in(project.owner)

    visit edit_project_path(project)
  end

  shared_examples 'changing visibility to private' do
    it 'requires confirmation' do
      visibility_select = first('.project-feature-controls .select-control')
      visibility_select.select('Private')

      page.within('#js-shared-permissions') do
        click_button 'Save changes'
      end

      find('.js-confirm-danger-input').send_keys(project.path_with_namespace)

      page.within '.modal' do
        click_button 'Reduce project visibility'
      end

      wait_for_requests

      expect(project.reload).to be_private
    end
  end

  context 'when a project is public' do
    let(:project) { create(:project, :empty_repo, :public) }

    it_behaves_like 'changing visibility to private'
  end

  context 'when the project is internal' do
    let(:project) { create(:project, :empty_repo, :internal) }

    it_behaves_like 'changing visibility to private'
  end
end
