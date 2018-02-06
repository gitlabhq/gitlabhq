require 'spec_helper'

describe 'New Branch Ref Dropdown', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:toggle) { find('.create-from .dropdown-menu-toggle') }

  before do
    project.add_master(user)

    sign_in(user)
    visit new_project_branch_path(project)
  end

  it 'filters a list of branches and tags' do
    toggle.click

    filter_by('v1.0.0')

    expect(items_count).to be(1)

    filter_by('video')

    expect(items_count).to be(1)

    find('.create-from .dropdown-content li').click

    expect(toggle).to have_content 'video'
  end

  it 'accepts a manually entered commit SHA' do
    toggle.click

    filter_by('somecommitsha')

    find('.create-from input[type=search]').send_keys(:enter)

    expect(toggle).to have_content 'somecommitsha'
  end

  def items_count
    all('.create-from .dropdown-content li').length
  end

  def filter_by(filter_text)
    fill_in 'Filter by Git revision', with: filter_text
  end
end
