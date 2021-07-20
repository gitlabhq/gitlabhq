# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root path' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  it 'shows the customize banner', :js do
    visit root_path

    expect(page).to have_content('Do you want to customize this page?')
  end
end
