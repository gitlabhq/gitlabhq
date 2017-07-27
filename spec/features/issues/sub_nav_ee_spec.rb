require 'spec_helper'

describe 'Issues sub nav EE' do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  it 'should have a `Boards` item' do
    expect(find('.sub-nav')).to have_content 'Boards'
  end
end
