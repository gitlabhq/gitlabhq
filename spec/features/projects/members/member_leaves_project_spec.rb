# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Member leaves project' do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
    stub_feature_flags(bootstrap_confirmation_modals: false)
  end

  it 'user leaves project' do
    visit project_path(project)

    click_link 'Leave project'

    expect(current_path).to eq(dashboard_projects_path)
    expect(project.users.exists?(user.id)).to be_falsey
  end

  it 'user leaves project by url param', :js do
    visit project_path(project, leave: 1)

    page.accept_confirm
    wait_for_all_requests

    expect(current_path).to eq(dashboard_projects_path)

    sign_in(project.first_owner)

    visit project_project_members_path(project)

    expect(members_table).not_to have_content(user.name)
  end
end
