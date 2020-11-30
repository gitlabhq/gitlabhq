# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Balsamiq file blob', :js do
  let(:project) { create(:project, :public, :repository) }

  before do
    visit project_blob_path(project, 'add-balsamiq-file/files/images/balsamiq.bmpr')

    wait_for_requests
  end

  it 'displays Balsamiq file content' do
    expect(page).to have_content("Mobile examples")
  end
end
