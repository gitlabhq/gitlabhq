require 'spec_helper'

feature 'Merge request tabs', js: true, feature: true do
  let(:user)          { create(:user) }
  let(:project)       { create(:project, :public) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: "Bug NS-04") }

  before do
    project.team << [user, :master]
    login_as user
    visit diffs_namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  it 'affixes to top of page when scrolling' do
    page.execute_script "window.scrollBy(0,10000)"
    expect(page).to have_selector('.js-tabs-affix.affix')
  end

  it 'removes affix when scrolling to top' do
    page.execute_script "window.scrollBy(0,10000)"
    expect(page).to have_selector('.js-tabs-affix.affix')

    page.execute_script "window.scrollBy(0,-10000)"
    expect(page).to have_selector('.js-tabs-affix.affix-top')
  end
end
