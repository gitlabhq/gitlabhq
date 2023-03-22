# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Anonymous user sees members' do
  include Features::MembersHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public) }

  before do
    project.add_maintainer(user)
    create(:project_group_link, project: project, group: group)
  end

  it "anonymous user visits the project's members page and sees the list of members", :js do
    visit project_project_members_path(project)

    expect(find_member_row(user)).to have_content(user.name)
  end
end
