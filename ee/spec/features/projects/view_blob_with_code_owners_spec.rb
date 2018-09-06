# frozen_string_literal: true

require 'spec_helper'

describe 'File blob > Code owners', :js do
  let(:project) { create(:project, :private, :repository) }
  let(:user) { project.owner }
  let(:code_owner) { create(:user, username: 'documentation-owner') }

  before do
    sign_in(user)
    project.add_developer(code_owner)
  end

  def visit_blob(path, anchor: nil, ref: 'master')
    visit project_blob_path(project, File.join(ref, path), anchor: anchor)

    wait_for_requests
  end

  context 'when there is a codeowners file' do
    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'shows the code owners related to a file' do
        visit_blob('docs/CODEOWNERS', ref: 'with-codeowners')

        within('.file-owner-content') do
          expect(page).to have_content('Code owners')
          expect(page).to have_link(code_owner.name)
        end
      end

      it 'does not show the code owners banner when there are no code owners' do
        visit_blob('README.md')

        expect(page).not_to have_content('Code owners:')
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'does not show the code owners related to a file' do
        visit_blob('docs/CODEOWNERS', ref: 'with-codeowners')

        expect(page).not_to have_content('Code owners')
      end
    end
  end
end
