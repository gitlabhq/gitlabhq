# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Secure Files', :js do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_ci_secure_files_path(project)
  end

  it 'user sees the Secure Files list component' do
    expect(page).to have_content('There are no records to show')
  end
end
