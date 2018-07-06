require 'spec_helper'

describe 'Projects > Members > Owner cannot leave project' do
  let(:project) { create(:project) }

  before do
    sign_in(project.owner)
    visit project_path(project)
  end

  it 'user does not see a "Leave project" link' do
    expect(page).not_to have_content 'Leave project'
  end
end
