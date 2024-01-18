# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Branch Ref Dropdown', :js, feature_category: :source_code_management do
  include ListboxHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:sha) { project.commit.sha }
  let(:toggle) { find('.ref-selector') }

  before do
    project.add_maintainer(user)

    sign_in(user)
    visit new_project_branch_path(project)
  end

  it 'finds a tag in a list' do
    tag_name = 'v1.0.0'

    filter_by(tag_name)

    wait_for_requests

    expect(items_count(tag_name)).to be(1)

    select_listbox_item tag_name

    expect(toggle).to have_content tag_name
  end

  it 'finds a branch in a list' do
    branch_name = 'audio'

    filter_by(branch_name)

    wait_for_requests

    expect(items_count(branch_name)).to be(1)

    select_listbox_item branch_name

    expect(toggle).to have_content branch_name
  end

  it 'finds a commit in a list' do
    filter_by(sha)

    wait_for_requests

    sha_short = sha[0, 7]

    expect(items_count(sha_short)).to be(1)

    select_listbox_item sha_short

    expect(toggle).to have_content sha_short
  end

  it 'shows no results when there is no branch, tag or commit sha found' do
    non_existing_ref = 'non_existing_branch_name'
    filter_by(non_existing_ref)

    wait_for_requests

    click_button 'master'
    expect(toggle).not_to have_content(non_existing_ref)
  end

  it 'passes accessibility tests' do
    click_button 'master'
    expect(page).to be_axe_clean.within('.ref-selector')
  end

  def item(ref_name)
    find('li', text: ref_name, match: :prefer_exact)
  end

  def items_count(ref_name)
    all('li', text: ref_name, match: :prefer_exact).length
  end

  def filter_by(filter_text)
    click_button 'master'
    send_keys filter_text
  end
end
