# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Owner cannot request access to their own project', feature_category: :groups_and_projects do
  let(:project) { create(:project, :repository) }

  before do
    sign_in(project.first_owner)
    visit project_path(project)
  end

  it 'owner does not see the request access button', :js do
    find_by_testid('projects-list-item-actions').click

    expect(page).not_to have_content 'Request access'
  end
end
