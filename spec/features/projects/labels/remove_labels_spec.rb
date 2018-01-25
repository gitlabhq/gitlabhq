require 'spec_helper'

describe 'Removing labels', :js do
  let(:user)     { create(:user) }
  let(:group)    { create(:group) }
  let(:project)  { create(:project, :public, namespace: group) }
  let!(:bug)     { create(:label, project: project, title: 'bug') }
  let!(:test)    { create(:label, project: project, title: 'test') }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'with a label list' do
    before do
      visit project_labels_path(project)
      wait_for_all_requests
    end

    it 'Deletes a label' do
      page.within '.labels' do
        first('.remove-row').click
        sleep 2
        page.execute_script('document.querySelector(".js-primary-button").click()')
        wait_for_requests
        expect(page.all('.remove-row').length).to eq 1
      end
    end
  end
end
