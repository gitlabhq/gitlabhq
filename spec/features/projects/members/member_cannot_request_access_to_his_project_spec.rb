require 'spec_helper'

describe 'Projects > Members > Member cannot request access to his project' do
  let(:member) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_developer(member)
    sign_in(member)
    visit project_path(project)
  end

  it 'member does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
