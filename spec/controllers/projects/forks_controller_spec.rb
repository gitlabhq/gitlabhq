require 'spec_helper'

describe Projects::ForksController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:forked_project) { Projects::ForkService.new(project, user).execute }
  let(:group) { create(:group, owner: forked_project.creator) }

  describe 'GET index' do
    def get_forks
      get :index,
        namespace_id: project.namespace.to_param,
        project_id: project.to_param
    end

    context 'when fork is public' do
      before { forked_project.update_attribute(:visibility_level, Project::PUBLIC) }

      it 'is visible for non logged in users' do
        get_forks

        expect(assigns[:forks]).to be_present
      end
    end

    context 'when fork is private' do
      before do
        forked_project.update_attributes(visibility_level: Project::PRIVATE, group: group)
      end

      it 'is not be visible for non logged in users' do
        get_forks

        expect(assigns[:forks]).to be_blank
      end

      context 'when user is logged in' do
        before { sign_in(project.creator) }

        context 'when user is not a Project member neither a group member' do
          it 'does not see the Project listed' do
            get_forks

            expect(assigns[:forks]).to be_blank
          end
        end

        context 'when user is a member of the Project' do
          before { forked_project.team << [project.creator, :developer] }

          it 'sees the project listed' do
            get_forks

            expect(assigns[:forks]).to be_present
          end
        end

        context 'when user is a member of the Group' do
          before { forked_project.group.add_developer(project.creator) }

          it 'sees the project listed' do
            get_forks

            expect(assigns[:forks]).to be_present
          end
        end
      end
    end
  end

  describe 'GET new' do
    context 'when user is not logged in' do

      it 'redirects to the sign-in page' do
        sign_out(user)

        get :new,
	  namespace_id: project.namespace.to_param,
          project_id: project.to_param

        expect(response).to redirect_to(root_path + 'users/sign_in')
      end
    end
  end
end
