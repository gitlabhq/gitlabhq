# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Member leaves project', feature_category: :subgroups do
  include Features::MembersHelpers
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, :with_namespace_settings) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'user leaves project' do
    visit project_path(project)

    click_link 'Leave project'

    expect(page).to have_current_path(dashboard_projects_path, ignore_query: true)
    expect(project.users.exists?(user.id)).to be_falsey
  end

  it 'user leaves project by url param', :js do
    visit project_path(project, leave: 1)

    accept_gl_confirm(button_text: 'Leave project')
    wait_for_all_requests

    expect(page).to have_current_path(dashboard_projects_path, ignore_query: true)

    sign_in(project.first_owner)

    visit project_project_members_path(project)

    expect(members_table).not_to have_content(user.name)
  end
end
