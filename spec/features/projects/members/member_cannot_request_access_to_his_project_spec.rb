# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Member cannot request access to their project', feature_category: :groups_and_projects do
  let(:member) { create(:user, :with_namespace) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_developer(member)
    sign_in(member)
    visit project_path(project)
  end

  it 'member does not see the request access button', :js do
    find_by_testid('projects-list-item-actions').click

    expect(page).not_to have_content 'Request access'
  end
end
