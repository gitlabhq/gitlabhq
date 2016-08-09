require 'spec_helper'

feature 'Edit Merge Request', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

  before do
    project.team << [user, :master]

    login_as user

    visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'editing a MR' do
    it 'has class js-quick-submit in form' do
      expect(page).to have_selector('.js-quick-submit')
    end
  end
end
