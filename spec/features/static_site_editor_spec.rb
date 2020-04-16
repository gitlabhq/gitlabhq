# frozen_string_literal: true

require 'spec_helper'

describe 'Static Site Editor' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_show_sse_path(project, 'master/README.md')
  end

  it 'renders Static Site Editor page' do
    expect(page).to have_selector('#static-site-editor')
  end
end
