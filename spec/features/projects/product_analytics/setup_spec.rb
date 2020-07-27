# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product Analytics > Setup' do
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'shows the setup instructions' do
    visit(setup_project_product_analytics_path(project))

    expect(page).to have_content('Copy the code below to implement tracking in your application')
  end
end
