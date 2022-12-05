# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a new project milestone', :js, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }

  before do
    login_as(user)
    visit new_project_milestone_path(project)
  end

  it 'description has emoji autocomplete' do
    find('#milestone_description').native.send_keys('')
    fill_in 'milestone_description', with: ':'

    expect(page).to have_selector('.atwho-view')
  end
end
