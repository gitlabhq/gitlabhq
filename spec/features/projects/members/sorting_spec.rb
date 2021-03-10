# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Sorting', :js do
  include Spec::Support::Helpers::Features::MembersHelpers

  let(:maintainer) { create(:user, name: 'John Doe') }
  let(:developer) { create(:user, name: 'Mary Jane', last_sign_in_at: 5.days.ago) }
  let(:project) { create(:project, namespace: maintainer.namespace, creator: maintainer) }

  before do
    create(:project_member, :developer, user: developer, project: project, created_at: 3.days.ago)

    sign_in(maintainer)
  end

  it 'sorts by account by default' do
    visit_members_list(sort: nil)

    expect(first_row).to have_content(maintainer.name)
    expect(second_row).to have_content(developer.name)

    expect_sort_by('Account', :asc)
  end

  it 'sorts by max role ascending' do
    visit_members_list(sort: :access_level_asc)

    expect(first_row).to have_content(developer.name)
    expect(second_row).to have_content(maintainer.name)

    expect_sort_by('Max role', :asc)
  end

  it 'sorts by max role descending' do
    visit_members_list(sort: :access_level_desc)

    expect(first_row).to have_content(maintainer.name)
    expect(second_row).to have_content(developer.name)

    expect_sort_by('Max role', :desc)
  end

  it 'sorts by access granted ascending' do
    visit_members_list(sort: :last_joined)

    expect(first_row).to have_content(maintainer.name)
    expect(second_row).to have_content(developer.name)

    expect_sort_by('Access granted', :asc)
  end

  it 'sorts by access granted descending' do
    visit_members_list(sort: :oldest_joined)

    expect(first_row).to have_content(developer.name)
    expect(second_row).to have_content(maintainer.name)

    expect_sort_by('Access granted', :desc)
  end

  it 'sorts by account ascending' do
    visit_members_list(sort: :name_asc)

    expect(first_row).to have_content(maintainer.name)
    expect(second_row).to have_content(developer.name)

    expect_sort_by('Account', :asc)
  end

  it 'sorts by account descending' do
    visit_members_list(sort: :name_desc)

    expect(first_row).to have_content(developer.name)
    expect(second_row).to have_content(maintainer.name)

    expect_sort_by('Account', :desc)
  end

  it 'sorts by last sign-in ascending', :clean_gitlab_redis_shared_state do
    visit_members_list(sort: :recent_sign_in)

    expect(first_row).to have_content(maintainer.name)
    expect(second_row).to have_content(developer.name)

    expect_sort_by('Last sign-in', :asc)
  end

  it 'sorts by last sign-in descending', :clean_gitlab_redis_shared_state do
    visit_members_list(sort: :oldest_sign_in)

    expect(first_row).to have_content(developer.name)
    expect(second_row).to have_content(maintainer.name)

    expect_sort_by('Last sign-in', :desc)
  end

  private

  def visit_members_list(sort:)
    visit project_project_members_path(project, sort: sort)
  end

  def first_member
    page.all('ul.content-list > li').first.text
  end

  def second_member
    page.all('ul.content-list > li').last.text
  end

  def expect_sort_by(text, sort_direction)
    within('[data-testid="members-sort-dropdown"]') do
      expect(page).to have_css('button[aria-haspopup="true"]', text: text)
      expect(page).to have_button("Sorting Direction: #{sort_direction == :asc ? 'Ascending' : 'Descending'}")
    end
  end
end
