# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Members > Member leaves project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'user leaves project' do
    visit project_path(project)

    click_link 'Leave project'

    expect(current_path).to eq(dashboard_projects_path)
    expect(project.users.exists?(user.id)).to be_falsey
  end

  it 'user leaves project by url param', :js, :quarantine do
    visit project_path(project, leave: 1)

    page.accept_confirm

    expect(find('.flash-notice')).to have_content "You left the \"#{project.full_name}\" project"
    expect(current_path).to eq(dashboard_projects_path)
    expect(project.users.exists?(user.id)).to be_falsey
  end
end
