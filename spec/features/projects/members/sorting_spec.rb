require 'spec_helper'

feature 'Projects > Members > Sorting', feature: true do
  let(:master)    { create(:user, name: 'John Doe') }
  let(:developer) { create(:user, name: 'Mary Jane', last_sign_in_at: 5.days.ago) }
  let(:project)   { create(:empty_project) }

  background do
    project.team << [master, :master]
    project.team << [developer, :developer]

    login_as(master)
  end

  scenario 'sorts alphabetically by default' do
    visit_members_list(sort: nil)

    expect(first_member).to include(master.name)
    expect(second_member).to include(developer.name)
  end

  scenario 'sorts by access level ascending' do
    visit_members_list(sort: :access_level_asc)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(master.name)
  end

  scenario 'sorts by access level descending' do
    visit_members_list(sort: :access_level_desc)

    expect(first_member).to include(master.name)
    expect(second_member).to include(developer.name)
  end

  scenario 'sorts by last joined' do
    visit_members_list(sort: :last_joined)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(master.name)
  end

  scenario 'sorts by oldest joined' do
    visit_members_list(sort: :oldest_joined)

    expect(first_member).to include(master.name)
    expect(second_member).to include(developer.name)
  end

  scenario 'sorts by name ascending' do
    visit_members_list(sort: :name_asc)

    expect(first_member).to include(master.name)
    expect(second_member).to include(developer.name)
  end

  scenario 'sorts by name descending' do
    visit_members_list(sort: :name_desc)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(master.name)
  end

  scenario 'sorts by recent sign in' do
    visit_members_list(sort: :recent_sign_in)

    expect(first_member).to include(master.name)
    expect(second_member).to include(developer.name)
  end

  scenario 'sorts by oldest sign in' do
    visit_members_list(sort: :oldest_sign_in)

    expect(first_member).to include(developer.name)
    expect(second_member).to include(master.name)
  end

  def visit_members_list(sort:)
    visit namespace_project_project_members_path(project.namespace.to_param, project.to_param, sort: sort)
  end

  def first_member
    page.all('ul.content-list > li').first.text
  end

  def second_member
    page.all('ul.content-list > li').last.text
  end
end
