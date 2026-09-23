# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Commits RSS', feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:path) { project_commits_path(project, :master) }

  before do
    stub_feature_flags(project_commits_refactor: false)
  end

  context 'when signed in' do
    before_all do
      project.add_developer(user)
    end

    before do
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

  context 'when project_commits_refactor is enabled' do
    before do
      stub_feature_flags(project_commits_refactor: true)
    end

    context 'when signed in', :js do
      before_all do
        project.add_developer(user)
      end

      before do
        sign_in(user)
        visit path
        click_button 'Actions'
      end

      it "shows the Commits feed link with current_user's feed token" do
        expect(page).to have_link 'Commits feed', href: /feed_token=glft-.*-#{user.id}/
      end

      it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
    end

    context 'when signed out', :js do
      before do
        visit path
        click_button 'Actions'
      end

      it 'shows the Commits feed link without a feed token' do
        expect(page).to have_link 'Commits feed'
        expect(page).not_to have_link 'Commits feed', href: /feed_token/
      end

      it_behaves_like "an autodiscoverable RSS feed without a feed token"
    end
  end
end
