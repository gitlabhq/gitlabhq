# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits feature flag user list', :js, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }

  before do
    project.add_developer(developer)
    sign_in(developer)
  end

  it 'prefills the edit form with the list name' do
    list = create(:operations_feature_flag_user_list, project: project, name: 'My List Name')

    visit(edit_project_feature_flags_user_list_path(project, list))

    expect(page).to have_field 'Name', with: 'My List Name'
  end
end
