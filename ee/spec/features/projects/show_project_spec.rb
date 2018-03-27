require 'spec_helper'

describe 'Project show page', :feature do
  describe 'stat button existence' do
    let(:user) { create(:user) }

    describe 'populated project' do
      let(:project) { create(:project, :public, :repository) }

      describe 'as a master' do
        before do
          project.add_master(user)
          sign_in(user)

          visit project_path(project)
        end

        it '"Kubernetes cluster" button linked to clusters page' do
          create(:cluster, :provided_by_gcp, projects: [project])
          create(:cluster, :provided_by_gcp, :production_environment, projects: [project])

          visit project_path(project)

          page.within('.project-stats') do
            expect(page).to have_link('Kubernetes configured', href: project_clusters_path(project))
          end
        end
      end
    end
  end
end
