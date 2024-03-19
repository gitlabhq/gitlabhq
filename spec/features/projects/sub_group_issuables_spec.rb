# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subgroup Issuables', :js, feature_category: :groups_and_projects do
  let!(:group)    { create(:group, name: 'group') }
  let!(:subgroup) { create(:group, parent: group, name: 'subgroup') }
  let!(:project)  { create(:project, namespace: subgroup, name: 'project') }
  let(:user)      { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in user
  end

  it 'shows the full subgroup title when issues index page is empty' do
    visit project_issues_path(project)

    expect_to_have_breadcrumb_links
  end

  it 'shows the full subgroup title when merge requests index page is empty' do
    visit project_merge_requests_path(project)

    expect_to_have_breadcrumb_links
  end

  def expect_to_have_breadcrumb_links
    links = find_by_testid('breadcrumb-links')

    expect(links).to have_content 'group subgroup project'
  end
end
