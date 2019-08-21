# frozen_string_literal: true

require 'spec_helper'

describe Explore::ProjectsController do
  shared_examples 'explore projects' do
    describe 'GET #index.json' do
      render_views

      before do
        get :index, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end

    describe 'GET #trending.json' do
      render_views

      before do
        get :trending, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end

    describe 'GET #starred.json' do
      render_views

      before do
        get :starred, format: :json
      end

      it { is_expected.to respond_with(:success) }
    end

    describe 'GET #trending' do
      context 'sorting by update date' do
        let(:project1) { create(:project, :public, updated_at: 3.days.ago) }
        let(:project2) { create(:project, :public, updated_at: 1.day.ago) }

        before do
          create(:trending_project, project: project1)
          create(:trending_project, project: project2)
        end

        it 'sorts by last updated' do
          get :trending, params: { sort: 'updated_desc' }

          expect(assigns(:projects)).to eq [project2, project1]
        end

        it 'sorts by oldest updated' do
          get :trending, params: { sort: 'updated_asc' }

          expect(assigns(:projects)).to eq [project1, project2]
        end
      end
    end
  end

  context 'when user is signed in' do
    let(:user) { create(:user) }

    before do
      sign_in(user)
    end

    include_examples 'explore projects'

    context 'user preference sorting' do
      let(:project) { create(:project) }

      it_behaves_like 'set sort order from user preference' do
        let(:sorting_param) { 'created_asc' }
      end
    end
  end

  context 'when user is not signed in' do
    include_examples 'explore projects'

    context 'user preference sorting' do
      let(:project) { create(:project) }
      let(:sorting_param) { 'created_asc' }

      it 'does not set sort order from user preference' do
        expect_any_instance_of(UserPreference).not_to receive(:update)

        get :index, params: { sort: sorting_param }
      end
    end
  end
end
