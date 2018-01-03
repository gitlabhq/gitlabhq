require 'spec_helper'

describe Explore::ProjectsController do
  describe 'GET #trending' do
    context 'sorting by update date' do
      let(:project1) { create(:project, :public, updated_at: 3.days.ago) }
      let(:project2) { create(:project, :public, updated_at: 1.day.ago) }

      before do
        create(:trending_project, project: project1)
        create(:trending_project, project: project2)
      end

      it 'sorts by last updated' do
        get :trending, sort: 'updated_desc'

        expect(assigns(:projects)).to eq [project2, project1]
      end

      it 'sorts by oldest updated' do
        get :trending, sort: 'updated_asc'

        expect(assigns(:projects)).to eq [project1, project2]
      end
    end
  end
end
