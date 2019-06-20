# frozen_string_literal: true

require 'spec_helper'

describe Projects::ForksController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:forked_project) { Projects::ForkService.new(project, user).execute }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
  end

  describe 'GET index' do
    def get_forks
      get :index,
        params: {
          namespace_id: project.namespace,
          project_id: project
        }
    end

    context 'when fork is public' do
      before do
        forked_project.update_attribute(:visibility_level, Project::PUBLIC)
      end

      it 'is visible for non logged in users' do
        get_forks

        expect(assigns[:forks]).to be_present
      end
    end

    context 'when fork is private' do
      before do
        forked_project.update(visibility_level: Project::PRIVATE, group: group)
      end

      it 'is not be visible for non logged in users' do
        get_forks

        expect(assigns[:forks]).to be_blank
      end

      context 'when user is logged in' do
        before do
          sign_in(project.creator)
        end

        context 'when user is not a Project member neither a group member' do
          it 'does not see the Project listed' do
            get_forks

            expect(assigns[:forks]).to be_blank
          end
        end

        context 'when user is a member of the Project' do
          before do
            forked_project.add_developer(project.creator)
          end

          it 'sees the project listed' do
            get_forks

            expect(assigns[:forks]).to be_present
          end
        end

        context 'when user is a member of the Group' do
          before do
            forked_project.group.add_developer(project.creator)
          end

          it 'sees the project listed' do
            get_forks

            expect(assigns[:forks]).to be_present
          end
        end
      end
    end
  end

  describe 'GET new' do
    def get_new
      get :new,
        params: {
          namespace_id: project.namespace,
          project_id: project
        }
    end

    context 'when user is signed in' do
      it 'responds with status 200' do
        sign_in(user)

        get_new

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when user is not signed in' do
      it 'redirects to the sign-in page' do
        sign_out(user)

        get_new

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'POST create' do
    def post_create(params = {})
      post :create,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          namespace_key: user.namespace.id
        }.merge(params)
    end

    context 'when user is signed in' do
      before do
        sign_in(user)
      end

      it 'responds with status 302' do
        post_create

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(namespace_project_import_path(user.namespace, project))
      end

      it 'passes continue params to the redirect' do
        continue_params = { to: '/-/ide/project/path', notice: 'message' }
        post_create continue: continue_params

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(namespace_project_import_path(user.namespace, project, continue: continue_params))
      end
    end

    context 'when user is not signed in' do
      it 'redirects to the sign-in page' do
        sign_out(user)

        post_create

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
