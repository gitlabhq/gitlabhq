# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a CRM contact', :js, feature_category: :service_desk do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let!(:crm_organization) { create(:crm_organization, group: group, name: 'GitLab') }

  before do
    group.add_owner(user)
    sign_in(user)
    visit new_group_crm_contact_path(group)
  end

  it 'creates a new contact' do
    fill_in 'firstName', with: 'Forename'
    fill_in 'lastName', with: 'Surname'
    fill_in 'email', with: 'gitlab@example.com'
    fill_in 'phone', with: '01234 555666'
    select 'GitLab', from: 'organizationId'
    fill_in 'description', with: 'VIP'
    click_button 'Save changes'

    wait_for_requests

    expect(group.contacts.first.email).to eq('gitlab@example.com')
    expect(page).to have_current_path("#{group_crm_contacts_path(group)}/", ignore_query: true)
  end
end
