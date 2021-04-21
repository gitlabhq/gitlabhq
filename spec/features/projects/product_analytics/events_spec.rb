# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product Analytics > Events' do
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }

  let(:event) { create(:product_analytics_event, project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'shows no events message' do
    visit(project_product_analytics_path(project))

    expect(page).to have_content('There are currently no events')
  end

  it 'shows events' do
    event

    visit(project_product_analytics_path(project))

    expect(page).to have_content('dvce_created_tstamp')
    expect(page).to have_content(event.event_id)
  end
end
