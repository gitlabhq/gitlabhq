# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product Analytics > Graphs' do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'shows graphs', :js do
    create(:product_analytics_event, project: project)

    visit(graphs_project_product_analytics_path(project))

    expect(page).to have_content('Showing graphs based on events')
    expect(page).to have_content('platform')
    expect(page).to have_content('os_timezone')
    expect(page).to have_content('br_lang')
    expect(page).to have_content('doc_charset')
  end
end
