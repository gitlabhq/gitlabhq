require 'spec_helper'

describe Explore::ProjectsController do
  let(:user) { create(:user) }
  let(:visibility) { :public }

  describe 'GET #trending' do
    let!(:project_1) { create(:project, visibility, ci_id: 1) }
    let!(:project_2) { create(:project, visibility, ci_id: 2) }

    let!(:trending_project_1) { create(:trending_project, project: project_1) }
    let!(:trending_project_2) { create(:trending_project, project: project_2) }

    before do
      sign_in(user)
    end

    context 'sorting by update date' do
      it 'sorts by last updated' do
        get :trending, sort: 'updated_desc'
        expect(assigns(:projects)).to eq [project_2, project_1]
      end

      it 'sorts by oldest updated' do
        get :trending, sort: 'updated_asc'
        expect(assigns(:projects)).to eq [project_1, project_2]
      end
    end
  end
end
