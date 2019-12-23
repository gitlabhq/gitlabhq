# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Raw > User interacts with raw endpoint' do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :public) }
  let(:file_path) { 'master/README.md' }

  before do
    stub_application_setting(raw_blob_request_limit: 3)
    project.add_developer(user)
    create_file_in_repo(project, 'master', 'master', 'README.md', 'readme content')

    sign_in(user)
  end

  context 'when user access a raw file' do
    it 'renders the page successfully' do
      visit project_raw_url(project, file_path)

      expect(source).to eq('') # Body is filled in by gitlab-workhorse
    end
  end

  context 'when user goes over the rate requests limit' do
    it 'returns too many requests' do
      4.times do
        visit project_raw_url(project, file_path)
      end

      expect(page).to have_content('You cannot access the raw file. Please wait a minute.')
    end
  end
end
