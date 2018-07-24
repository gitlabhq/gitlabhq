require 'spec_helper'

describe 'Issues sub nav EE' do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  it 'should have a `Boards` item' do
    expect(find('.nav-sidebar')).to have_content 'Boards'
  end
end
