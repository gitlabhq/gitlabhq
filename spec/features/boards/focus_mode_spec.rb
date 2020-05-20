# frozen_string_literal: true

require 'spec_helper'

describe 'Issue Boards focus mode', :js do
  let(:project) { create(:project, :public) }

  before do
    visit project_boards_path(project)

    wait_for_requests
  end

  it 'shows focus mode button to guest users' do
    expect(page).to have_selector('.board-extra-actions .js-focus-mode-btn')
  end
end
