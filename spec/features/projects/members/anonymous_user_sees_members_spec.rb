# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Anonymous user sees members' do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public) }

  before do
    project.add_maintainer(user)
    create(:project_group_link, project: project, group: group)
  end

  context 'when `vue_project_members_list` feature flag is enabled', :js do
    it "anonymous user visits the project's members page and sees the list of members" do
      visit project_project_members_path(project)

      expect(find_member_row(user)).to have_content(user.name)
    end
  end

  context 'when `vue_project_members_list` feature flag is disabled' do
    before do
      stub_feature_flags(vue_project_members_list: false)
    end

    it "anonymous user visits the project's members page and sees the list of members" do
      visit project_project_members_path(project)

      expect(current_path).to eq(
        project_project_members_path(project))
      expect(page).to have_content(user.name)
    end
  end
end
