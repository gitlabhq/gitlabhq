require 'spec_helper'

feature 'Download buttons in tags page', feature: true do
  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:status) { 'success' }
  given(:tag) { 'v1.0.0' }
  given(:project) { create(:project) }

  given(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit(tag).sha,
           ref: tag,
           status: status)
  end

  given!(:build) do
    create(:ci_build, :success, :artifacts,
           pipeline: pipeline,
           status: pipeline.status,
           name: 'build')
  end

  background do
    login_as(user)
    project.team << [user, role]
  end

  describe 'when checking tags' do
    context 'with artifacts' do
      before do
        visit namespace_project_tags_path(project.namespace, project)
      end

      scenario 'shows download artifacts button' do
        expect(page).to have_link "Download '#{build.name}'"
      end
    end
  end
end
