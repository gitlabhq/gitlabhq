# frozen_string_literal: true

require 'spec_helper'

describe Projects::StarrersController do
  let(:user) { create(:user) }
  let(:private_user) { create(:user, private_profile: true) }
  let(:admin) { create(:user, admin: true) }
  let(:project) { create(:project, :public, :repository) }

  before do
    user.toggle_star(project)
    private_user.toggle_star(project)
  end

  describe 'GET index' do
    def get_starrers
      get :index,
        params: {
          namespace_id: project.namespace,
          project_id: project
        }
    end

    context 'when project is public' do
      before do
        project.update_attribute(:visibility_level, Project::PUBLIC)
      end

      context 'when no user is logged in' do
        before do
          get_starrers
        end

        it 'only public starrers are visible' do
          user_ids = assigns[:starrers].map { |s| s['user_id'] }
          expect(user_ids).to include(user.id)
          expect(user_ids).not_to include(private_user.id)
        end

        it 'public/private starrers counts are correct' do
          expect(assigns[:public_count]).to eq(1)
          expect(assigns[:private_count]).to eq(1)
        end
      end

      context 'when private user is logged in' do
        before do
          sign_in(private_user)

          get_starrers
        end

        it 'their star is also visible' do
          user_ids = assigns[:starrers].map { |s| s['user_id'] }
          expect(user_ids).to include(user.id, private_user.id)
        end

        it 'public/private starrers counts are correct' do
          expect(assigns[:public_count]).to eq(1)
          expect(assigns[:private_count]).to eq(1)
        end
      end

      context 'when admin is logged in' do
        before do
          sign_in(admin)

          get_starrers
        end

        it 'all stars are visible' do
          user_ids = assigns[:starrers].map { |s| s['user_id'] }
          expect(user_ids).to include(user.id, private_user.id)
        end

        it 'public/private starrers counts are correct' do
          expect(assigns[:public_count]).to eq(1)
          expect(assigns[:private_count]).to eq(1)
        end
      end
    end

    context 'when project is private' do
      before do
        project.update(visibility_level: Project::PRIVATE)
      end

      it 'starrers are not visible for non logged in users' do
        get_starrers

        expect(assigns[:starrers]).to be_blank
      end

      context 'when user is logged in' do
        before do
          sign_in(project.creator)
        end

        it 'only public starrers are visible' do
          get_starrers

          user_ids = assigns[:starrers].map { |s| s['user_id'] }
          expect(user_ids).to include(user.id)
          expect(user_ids).not_to include(private_user.id)
        end
      end
    end
  end
end
