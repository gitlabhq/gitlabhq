# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ReleasesController do
  let(:group) { create(:group) }
  let!(:project)         { create(:project, :repository, :public, namespace: group) }
  let!(:private_project) { create(:project, :repository, :private, namespace: group) }
  let(:guest) { create(:user) }
  let!(:release_1)       { create(:release, project: project, tag: 'v1', released_at: Time.zone.parse('2020-02-15')) }
  let!(:release_2)       { create(:release, project: project, tag: 'v2', released_at: Time.zone.parse('2020-02-20')) }
  let!(:private_release_1)       { create(:release, project: private_project, tag: 'p1', released_at: Time.zone.parse('2020-03-01')) }
  let!(:private_release_2)       { create(:release, project: private_project, tag: 'p2', released_at: Time.zone.parse('2020-03-05')) }

  before do
    group.add_guest(guest)
  end

  describe 'GET #index' do
    context 'as json' do
      let(:format) { :json }

      subject(:index) { get :index, params: { group_id: group }, format: format }

      context 'json_response' do
        before do
          index
        end

        it 'returns an application/json content_type' do
          expect(response.media_type).to eq 'application/json'
        end

        it 'returns OK' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'the user is not authorized' do
        before do
          index
        end

        it 'does not return any releases' do
          expect(json_response.map { |r| r['tag'] }).to be_empty
        end

        it 'returns OK' do
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'the user is authorized' do
        it "returns all group's public and private project's releases as JSON, ordered by released_at" do
          sign_in(guest)

          index

          expect(json_response.map { |r| r['tag'] }).to match_array(%w[p2 p1 v2 v1])
        end
      end

      context 'N+1 queries' do
        it 'avoids N+1 database queries' do
          control = ActiveRecord::QueryRecorder.new { subject }

          create_list(:release, 5, project: project)
          create_list(:release, 5, project: private_project)

          expect { subject }.not_to exceed_query_limit(control)
        end
      end
    end
  end
end
