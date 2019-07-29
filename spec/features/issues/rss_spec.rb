# frozen_string_literal: true

require 'spec_helper'

describe 'Project Issues RSS' do
  let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:path) { project_issues_path(project) }

  before do
    create(:issue, project: project)
  end

  context 'when signed in' do
    let(:user) { create(:user) }

    before do
      project.add_developer(user)
      sign_in(user)
      visit path
    end

    it_behaves_like "it has an RSS button with current_user's feed token"
    it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
  end

  context 'when signed out' do
    before do
      visit path
    end

    it_behaves_like "it has an RSS button without a feed token"
    it_behaves_like "an autodiscoverable RSS feed without a feed token"
  end
end
