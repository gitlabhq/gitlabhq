require 'spec_helper'

describe 'Issues sub nav EE', :feature do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  before do
    project.add_master(user)
    login_as(user)

    visit namespace_project_issues_path(project.namespace, project)
  end

  it 'should have a `Boards` item' do
    expect(find('.sub-nav')).to have_content 'Boards'
  end
end
