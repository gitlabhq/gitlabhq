# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::StarrersController do
  let(:user_1) { create(:user, name: 'John') }
  let(:user_2) { create(:user, name: 'Michael') }
  let(:private_user) { create(:user, name: 'Michael Douglas', private_profile: true) }
  let(:admin) { create(:user, admin: true) }
  let(:project) { create(:project, :public) }

  before do
    user_1.toggle_star(project)
    user_2.toggle_star(project)
    private_user.toggle_star(project)
  end

  describe 'GET index' do
    def get_starrers(search: nil)
      get :index, params: { namespace_id: project.namespace, project_id: project, search: search }
    end

    def user_ids
      assigns[:starrers].map { |s| s['user_id'] }
    end

    shared_examples 'starrers counts' do
      it 'starrers counts are correct' do
        expect(assigns[:total_count]).to eq(3)
        expect(assigns[:public_count]).to eq(2)
        expect(assigns[:private_count]).to eq(1)
      end
    end

    context 'N+1 queries' do
      render_views

      it 'avoids N+1s loading users', :request_store do
        get_starrers

        control_count = ActiveRecord::QueryRecorder.new { get_starrers }.count

        create_list(:user, 5).each { |user| user.toggle_star(project) }

        expect { get_starrers }.not_to exceed_query_limit(control_count)
      end
    end

    context 'when project is public' do
      before do
        project.update_attribute(:visibility_level, Project::PUBLIC)
      end

      context 'when no user is logged in' do
        context 'with no searching' do
          before do
            get_starrers
          end

          it 'only users with public profiles are visible' do
            expect(user_ids).to contain_exactly(user_1.id, user_2.id)
          end

          include_examples 'starrers counts'
        end

        context 'when searching by user' do
          before do
            get_starrers(search: 'Michael')
          end

          it 'only users with public profiles are visible' do
            expect(user_ids).to contain_exactly(user_2.id)
          end

          include_examples 'starrers counts'
        end
      end

      context 'when public user is logged in' do
        before do
          sign_in(user_1)
        end

        context 'with no searching' do
          before do
            get_starrers
          end

          it 'their star is also visible' do
            expect(user_ids).to contain_exactly(user_1.id, user_2.id)
          end

          include_examples 'starrers counts'
        end

        context 'when searching by user' do
          before do
            get_starrers(search: 'Michael')
          end

          it 'only users with public profiles are visible' do
            expect(user_ids).to contain_exactly(user_2.id)
          end

          include_examples 'starrers counts'
        end
      end

      context 'when private user is logged in' do
        before do
          sign_in(private_user)
        end

        context 'with no searching' do
          before do
            get_starrers
          end

          it 'their star is also visible' do
            expect(user_ids).to contain_exactly(user_1.id, user_2.id, private_user.id)
          end

          include_examples 'starrers counts'
        end

        context 'when searching by user' do
          before do
            get_starrers(search: 'Michael')
          end

          it 'only users with public profiles are visible' do
            expect(user_ids).to contain_exactly(user_2.id, private_user.id)
          end

          include_examples 'starrers counts'
        end
      end

      context 'when admin is logged in' do
        before do
          sign_in(admin)
        end

        context 'with no searching' do
          before do
            get_starrers
          end

          it 'all users are visible' do
            expect(user_ids).to include(user_1.id, user_2.id, private_user.id)
          end

          include_examples 'starrers counts'
        end

        context 'when searching by user' do
          before do
            get_starrers(search: 'Michael')
          end

          it 'public and private starrers are visible' do
            expect(user_ids).to contain_exactly(user_2.id, private_user.id)
          end

          include_examples 'starrers counts'
        end
      end
    end

    context 'when project is private' do
      before do
        project.update!(visibility_level: Project::PRIVATE)
      end

      it 'starrers are not visible for non logged in users' do
        get_starrers

        expect(assigns[:starrers]).to be_blank
      end

      context 'when user is logged in' do
        before do
          sign_in(project.creator)
          get_starrers
        end

        it 'only users with public profiles are visible' do
          expect(user_ids).to contain_exactly(user_1.id, user_2.id)
        end

        include_examples 'starrers counts'
      end
    end
  end
end
