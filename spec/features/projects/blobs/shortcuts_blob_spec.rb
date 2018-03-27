require 'spec_helper'

feature 'Blob shortcuts' do
  include TreeHelper
  let(:project) { create(:project, :public, :repository) }
  let(:path) { project.repository.ls_files(project.repository.root_ref)[0] }
  let(:sha) { project.repository.commit.sha }

  describe 'On a file(blob)', :js do
    def get_absolute_url(path = "")
      "http://#{page.server.host}:#{page.server.port}#{path}"
    end

    def visit_blob(fragment = nil)
      visit project_blob_path(project, tree_join('master', path), anchor: fragment)
    end

    describe 'pressing "y"' do
      it 'redirects to permalink with commit sha' do
        visit_blob

        find('body').native.send_key('y')

        expect(page).to have_current_path(get_absolute_url(project_blob_path(project, tree_join(sha, path))), url: true)
      end

      it 'maintains fragment hash when redirecting' do
        fragment = "L1"
        visit_blob(fragment)

        find('body').native.send_key('y')

        expect(page).to have_current_path(get_absolute_url(project_blob_path(project, tree_join(sha, path), anchor: fragment)), url: true)
      end
    end
  end
end
