require 'spec_helper'

describe 'Project show page', feature: true do
  context 'when project pending delete' do
    let(:project) { create(:project, :empty_repo, pending_delete: true) }
    let(:worker) { ProjectDestroyWorker.new }

    before do
      sign_in(project.owner)
    end

    it 'shows flash error if deletion for project fails' do
      error_message = "some error message"
      project.update_attributes(delete_error: error_message, pending_delete: false)

      visit namespace_project_path(project.namespace, project)

      expect(page).to have_selector('.project-deletion-failed-message')
      expect(page).to have_content("This project was scheduled for deletion, but failed with the following message: #{error_message}")
    end

    it 'renders 404 if project was successfully deleted' do
      worker.perform(project.id, project.owner.id, {})

      visit namespace_project_path(project.namespace, project)

      expect(page).to have_http_status(404)
    end
  end
end
