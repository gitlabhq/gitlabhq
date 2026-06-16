# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::MilestonesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, maintainers: user) }
  let_it_be(:group) { create(:group, developers: user) }
  let_it_be(:project_milestone) { create(:milestone, project: project) }
  let_it_be(:group_milestone) { create(:milestone, group: group) }

  before do
    sign_in(user)
  end

  describe "#index" do
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:public_milestone) { create(:milestone, group: public_group) }
    let_it_be(:closed_group_milestone) { create(:milestone, group: group, state: 'closed') }
    let_it_be(:closed_project_milestone) { create(:milestone, project: project, state: 'closed') }

    render_views

    it 'returns group and project milestones to which the user belongs' do
      get :index, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(2)
      expect(json_response.map { |i| i["name"] }).to match_array([group_milestone.name, project_milestone.name])
    end

    it 'returns closed group and project milestones to which the user belongs' do
      get :index, params: { state: 'closed' }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(2)
      expect(json_response.map { |i| i["name"] }).to match_array([closed_group_milestone.name, closed_project_milestone.name])
    end

    it 'searches legacy project milestones by title when search_title is given' do
      project_milestone = create(:milestone, title: 'Project milestone title', project: project)

      get :index, params: { search_title: 'Project mil' }

      expect(response.body).to include(project_milestone.title)
      expect(response.body).not_to include(group_milestone.title)
    end

    it 'searches group milestones by title when search_title is given' do
      group_milestone = create(:milestone, title: 'Group milestone title', group: group)

      get :index, params: { search_title: 'Group mil' }

      expect(response.body).to include(group_milestone.title)
      expect(response.body).not_to include(project_milestone.title)
    end

    it 'shows counts of open/closed/all group and project milestones to which the user belongs to' do
      get :index

      expect(response.body).to have_content('Open 2')
      expect(response.body).to have_content('Closed 2')
      expect(response.body).to have_content('All 4')
    end

    context 'external authorization' do
      subject { get :index }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end
end
