require 'spec_helper'

describe "Admin::Emails", feature: true, js: true do
  let!(:current_user) { create(:admin) }
  let!(:group) { create(:group) }
  let!(:project) { create(:project, namespace: group) }

  describe "GET /admin/email" do
    before do
      sign_in(current_user)
      visit admin_email_path
    end

    describe 'Recipient group select' do
      it "includes groups and projects" do
        find('.ajax-admin-email-select').click
        wait_for_requests

        expect(page).to have_selector('.ajax-admin-email-dropdown li', count: 3)
        group_names = page.all('.ajax-admin-email-dropdown li .group-name')
        expect(group_names[0].text).to eq('All')
        expect(group_names[1].text).to eq(group.name)
        expect(find('.ajax-admin-email-dropdown li .project-name').text).to eq(project.name)
      end
    end
  end
end
