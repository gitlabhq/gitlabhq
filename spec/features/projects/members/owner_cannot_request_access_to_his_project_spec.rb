# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Owner cannot request access to their own project', feature_category: :groups_and_projects do
  let(:project) { create(:project) }

  before do
    sign_in(project.first_owner)
    visit project_path(project)
  end

  it 'owner does not see the request access button' do
    expect(page).not_to have_content 'Request Access'
  end
end
