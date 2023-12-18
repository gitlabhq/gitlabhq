# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'User views tags', :feature, feature_category: :source_code_management do
  include_examples 'user views tag' do
    let(:tag_page) { project_tags_path(project) }
  end

  context 'rss' do
    shared_examples 'has access to the tags RSS feed' do
      it do
        visit project_tags_path(project, format: :atom)

        expect(page).to have_gitlab_http_status(:ok)
      end
    end

    shared_examples 'does not have access to the tags RSS feed' do
      it do
        visit project_tags_path(project, format: :atom)

        expect(page).to have_current_path("/users/sign_in")
      end
    end

    context 'when project public' do
      let(:project) { create(:project, :repository, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

      context 'when user signed in' do
        let(:user) { create(:user) }

        before do
          project.add_developer(user)
          sign_in(user)
          visit project_tags_path(project)
        end

        it_behaves_like "it has an RSS button with current_user's feed token"
        it_behaves_like "an autodiscoverable RSS feed with current_user's feed token"
        it_behaves_like 'has access to the tags RSS feed'
        it 'passes axe automated accessibility testing', :js do
          expect(page).to be_axe_clean.within('#content-body')
        end
      end

      context 'when user signed out' do
        before do
          visit project_tags_path(project)
        end

        it_behaves_like 'it has an RSS button without a feed token'
        it_behaves_like 'an autodiscoverable RSS feed without a feed token'
        it_behaves_like 'has access to the tags RSS feed'
      end
    end

    context 'when project is not public' do
      let(:project) { create(:project, :repository, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }

      context 'when user signed in' do
        let(:user) { create(:user) }

        before do
          project.add_developer(user)
          sign_in(user)
        end

        it_behaves_like 'has access to the tags RSS feed'
      end

      context 'when user signed out' do
        it_behaves_like 'does not have access to the tags RSS feed'
      end
    end
  end
end
