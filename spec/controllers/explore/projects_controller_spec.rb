require 'spec_helper'

describe Explore::ProjectsController do
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
