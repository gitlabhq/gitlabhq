require 'spec_helper'

describe 'Projects > Members > Member leaves project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(user)
    sign_in(user)
    visit project_path(project)
  end

  it 'user leaves project' do
    click_link 'Leave project'

    expect(current_path).to eq(dashboard_projects_path)
    expect(project.users.exists?(user.id)).to be_falsey
  end
end
