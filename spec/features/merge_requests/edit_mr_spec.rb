require 'spec_helper'

feature 'Edit Merge Request', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:merge_request) { create(:merge_request, :with_diffs, source_project: project) }

  before do
    project.team << [user, :master]
    project.update_attributes(approvals_before_merge: 2)

    login_as user

    visit edit_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  context 'editing a MR that needs approvals' do
    it 'form should have class js-quick-submit' do
      expect(page).to have_selector('.js-quick-submit')
    end

    context 'saving the MR' do
      it 'shows the saved MR' do
        click_button 'Save changes'

        expect(page).to have_link('Close merge request')
      end
    end
  end
end
