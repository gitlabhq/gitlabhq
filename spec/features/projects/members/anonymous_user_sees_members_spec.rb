# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Members > Anonymous user sees members' do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public) }

  before do
    project.add_maintainer(user)
    create(:project_group_link, project: project, group: group)
  end

  it "anonymous user visits the project's members page and sees the list of members" do
    visit project_project_members_path(project)

    expect(current_path).to eq(
      project_project_members_path(project))
    expect(page).to have_content(user.name)
  end
end
