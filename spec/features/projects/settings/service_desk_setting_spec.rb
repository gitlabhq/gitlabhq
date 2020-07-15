# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service Desk Setting', :js do
  let(:project) { create(:project_empty_repo, :private, service_desk_enabled: false) }
  let(:presenter) { project.present(current_user: user) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    allow_any_instance_of(Project).to receive(:present).with(current_user: user).and_return(presenter)
    allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

    visit edit_project_path(project)
  end

  it 'shows activation checkbox' do
    expect(page).to have_selector("#service-desk-checkbox")
  end

  it 'shows incoming email after activating' do
    find("#service-desk-checkbox").click
    wait_for_requests
    project.reload
    expect(project.service_desk_enabled).to be_truthy
    expect(project.service_desk_address).to be_present
    expect(find('.incoming-email').value).to eq(project.service_desk_address)
  end
end
