# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Group member cannot request access to their group project',
  feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  it 'owner does not see the request access button' do
    group.add_owner(user)
    login_and_visit_project_page(user)

    expect(page).not_to have_content 'Request Access'
  end

  it 'maintainer does not see the request access button' do
    group.add_maintainer(user)
    login_and_visit_project_page(user)

    expect(page).not_to have_content 'Request Access'
  end

  it 'developer does not see the request access button' do
    group.add_developer(user)
    login_and_visit_project_page(user)

    expect(page).not_to have_content 'Request Access'
  end

  it 'reporter does not see the request access button' do
    group.add_reporter(user)
    login_and_visit_project_page(user)

    expect(page).not_to have_content 'Request Access'
  end

  it 'guest does not see the request access button' do
    group.add_guest(user)
    login_and_visit_project_page(user)

    expect(page).not_to have_content 'Request Access'
  end

  def login_and_visit_project_page(user)
    sign_in(user)
    visit project_path(project)
  end
end
