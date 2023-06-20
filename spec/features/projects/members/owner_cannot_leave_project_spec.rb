# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Owner cannot leave project', feature_category: :groups_and_projects do
  let(:project) { create(:project) }

  before do
    sign_in(project.first_owner)
    visit project_path(project)
  end

  it 'user does not see a "Leave project" link' do
    expect(page).not_to have_content 'Leave project'
  end
end
