# frozen_string_literal: true
require 'rails_helper'

describe Groups::RoadmapController do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }

  before do
    stub_licensed_features(epics: true)
  end

  describe 'GET /groups/*namespace_id/-/roadmap' do
    let(:layout) { 'WEEKS' }

    context 'guest' do
      it 'renders without persisting layout' do
        expect do
          get group_roadmap_path(group, layout: layout)
        end.not_to change { user.reload.roadmap_layout }

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'logged in' do
      before do
        allow(Users::UpdateService).to receive(:new).and_call_original
        group.add_maintainer(user)
        login_as user
      end

      context 'not specifying layout' do
        it 'renders without persisting layout' do
          expect(Users::UpdateService).not_to receive(:new).with(user, user: user, roadmap_layout: a_kind_of(String))
          expect do
            get group_roadmap_path(group)
          end.not_to change { user.reload.roadmap_layout }

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'specifying invalid layout' do
        it 'renders without persisting layout' do
          expect(Users::UpdateService).not_to receive(:new).with(user, user: user, roadmap_layout: a_kind_of(String))
          get group_roadmap_path(group, layout: 'FOO')

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'specifying layout' do
        it 'persists roadmap_layout if different than current layout' do
          expect(Users::UpdateService).to receive(:new).with(user, user: user, roadmap_layout: layout).once.and_call_original

          expect do
            get group_roadmap_path(group, layout: layout)
            get group_roadmap_path(group, layout: layout)
          end.to change { user.reload.roadmap_layout }.to(layout)

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end
  end
end
