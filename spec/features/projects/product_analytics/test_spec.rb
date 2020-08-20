# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product Analytics > Test' do
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'says it sends a payload' do
    visit(test_project_product_analytics_path(project))

    expect(page).to have_content('This page sends a payload.')
  end

  it 'shows the last event if there is one' do
    event = create(:product_analytics_event, project: project)

    visit(test_project_product_analytics_path(project))

    expect(page).to have_content(event.event_id)
  end
end
