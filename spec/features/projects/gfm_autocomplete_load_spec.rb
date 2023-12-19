# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GFM autocomplete loading', :js, feature_category: :team_planning do
  let(:project) { create(:project) }

  before do
    sign_in(project.first_owner)

    visit project_path(project)
  end

  it 'does not load on project#show' do
    expect(evaluate_script('gl.GfmAutoComplete')).to eq(nil)
  end

  it 'loads on new issue page' do
    visit new_project_issue_path(project)

    expect(evaluate_script('gl.GfmAutoComplete.dataSources')).not_to eq({})
  end
end
