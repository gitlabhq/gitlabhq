# frozen_string_literal: true

require 'spec_helper'

describe 'Root explore' do
  set(:public_project) { create(:project, :public) }
  set(:archived_project) { create(:project, :archived) }
  set(:internal_project) { create(:project, :internal) }
  set(:private_project) { create(:project, :private) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  context 'when logged in' do
    set(:user) { create(:user) }

    before do
      sign_in(user)
      visit explore_projects_path
    end

    include_examples 'shows public and internal projects'
  end

  context 'when not logged in' do
    before do
      visit explore_projects_path
    end

    include_examples 'shows public projects'
  end
end
