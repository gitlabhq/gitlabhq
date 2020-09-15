# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Static Site Editor' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_show_sse_path(project, 'master/README.md')
  end

  it 'renders Static Site Editor page with generated and file attributes' do
    # assert generated config value is present
    expect(page).to have_css('#static-site-editor[data-branch="master"]')

    # assert file config value is present
    expect(page).to have_css('#static-site-editor[data-static-site-generator="middleman"]')
  end
end
