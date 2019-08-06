# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Members > Sorting' do
  let(:maintainer) { create(:user, name: 'John Doe') }
  let(:developer) { create(:user, name: 'Mary Jane', last_sign_in_at: 5.days.ago) }
  let(:project) { create(:project, namespace: maintainer.namespace, creator: maintainer) }

  before do
    create(:project_member, :developer, user: developer, project: project, created_at: 3.days.ago)

    sign_in(maintainer)
  end

  it 'sorts alphabetically by default' do
    visit_members_list(sort: nil)

    expect(first_member).to include(maintainer.name)
    expect(second_member).to include(developer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Name, ascending')
  end

  it 'sorts by access level ascending' do
    visit_members_list(sort: :access_level_asc)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(maintainer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Access level, ascending')
  end

  it 'sorts by access level descending' do
    visit_members_list(sort: :access_level_desc)

    expect(first_member).to include(maintainer.name)
    expect(second_member).to include(developer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Access level, descending')
  end

  it 'sorts by last joined' do
    visit_members_list(sort: :last_joined)

    expect(first_member).to include(maintainer.name)
    expect(second_member).to include(developer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Last joined')
  end

  it 'sorts by oldest joined' do
    visit_members_list(sort: :oldest_joined)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(maintainer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Oldest joined')
  end

  it 'sorts by name ascending' do
    visit_members_list(sort: :name_asc)

    expect(first_member).to include(maintainer.name)
    expect(second_member).to include(developer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Name, ascending')
  end

  it 'sorts by name descending' do
    visit_members_list(sort: :name_desc)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(maintainer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Name, descending')
  end

  it 'sorts by recent sign in', :clean_gitlab_redis_shared_state do
    visit_members_list(sort: :recent_sign_in)

    expect(first_member).to include(maintainer.name)
    expect(second_member).to include(developer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Recent sign in')
  end

  it 'sorts by oldest sign in', :clean_gitlab_redis_shared_state do
    visit_members_list(sort: :oldest_sign_in)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(maintainer.name)
    expect(page).to have_css('.qa-member-sort-dropdown .dropdown-toggle-text', text: 'Oldest sign in')
  end

  def visit_members_list(sort:)
    visit project_project_members_path(project, sort: sort)
  end

  def first_member
    page.all('ul.content-list > li').first.text
  end

  def second_member
    page.all('ul.content-list > li').last.text
  end
end
