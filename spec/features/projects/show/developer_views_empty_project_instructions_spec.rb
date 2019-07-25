# frozen_string_literal: true

require 'rails_helper'

describe 'Projects > Show > Developer views empty project instructions' do
  let(:project) { create(:project, :empty_repo) }
  let(:developer) { create(:user) }

  before do
    project.add_developer(developer)

    sign_in(developer)
  end

  it 'displays "git clone" instructions' do
    visit project_path(project)

    expect(page).to have_content("git clone")
  end
end
