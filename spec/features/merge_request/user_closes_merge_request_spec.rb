# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User closes a merge requests', :js do
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(merge_request_path(merge_request))
  end

  it 'closes a merge request' do
    click_button('Close merge request', match: :first)

    expect(page).to have_content(merge_request.title)
    expect(page).to have_content('Closed by')
  end
end
