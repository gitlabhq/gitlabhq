# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards focus mode', :js, feature_category: :portfolio_management do
  let(:project) { create(:project, :public) }

  before do
    visit project_boards_path(project)

    wait_for_requests
  end

  it 'shows focus mode button to anonymous users' do
    expect(page).to have_button _('Toggle focus mode')
  end
end
