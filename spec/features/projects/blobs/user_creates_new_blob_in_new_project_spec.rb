# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates new blob', :js do
  include WebIdeSpecHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :empty_repo) }

  shared_examples 'creating a file' do
    before do
      sign_in(user)
      visit project_path(project)
    end

    it 'allows the user to add a new file in Web IDE' do
      click_link 'New file'

      wait_for_requests

      ide_create_new_file('dummy-file', content: "Hello world\n")

      ide_commit

      expect(page).to have_content('All changes are committed')
      expect(project.repository.blob_at('master', 'dummy-file').data).to eql("Hello world\n")
    end
  end

  describe 'as a maintainer' do
    before do
      project.add_maintainer(user)
    end

    it_behaves_like 'creating a file'
  end

  describe 'as an admin' do
    let(:user) { create(:user, :admin) }

    it_behaves_like 'creating a file'
  end

  describe 'as a developer' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit project_path(project)
    end

    it 'does not allow pushing to the default branch' do
      expect(page).not_to have_content('New file')
    end
  end
end
