# frozen_string_literal: true

require 'spec_helper'

describe RoutableActions do
  controller(::ApplicationController) do
    include RoutableActions

    before_action :routable

    def routable
      @klass = params[:type].constantize
      @routable = find_routable!(params[:type].constantize, params[:id])
    end

    def show
      head :ok
    end
  end

  def get_routable(routable)
    get :show, params: { id: routable.full_path, type: routable.class }
  end

  describe '#find_routable!' do
    context 'when signed in' do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      context 'with a project' do
        let(:routable) { create(:project) }

        context 'when authorized' do
          before do
            routable.add_guest(user)
          end

          it 'returns the project' do
            get_routable(routable)

            expect(assigns[:routable]).to be_a(Project)
          end

          it 'allows access' do
            get_routable(routable)

            expect(response).to have_gitlab_http_status(200)
          end
        end

        it 'prevents access when not authorized' do
          get_routable(routable)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'with a group' do
        let(:routable) { create(:group, :private) }

        context 'when authorized' do
          before do
            routable.add_guest(user)
          end

          it 'returns the group' do
            get_routable(routable)

            expect(assigns[:routable]).to be_a(Group)
          end

          it 'allows access' do
            get_routable(routable)

            expect(response).to have_gitlab_http_status(200)
          end
        end

        it 'prevents access when not authorized' do
          get_routable(routable)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'with a user' do
        let(:routable) { user }

        it 'allows access when authorized' do
          get_routable(routable)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'prevents access when unauthorized' do
          allow(subject).to receive(:can?).and_return(false)

          get_routable(user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when not signed in' do
      it 'redirects to sign in for private resouces' do
        routable = create(:project, :private)

        get_routable(routable)

        expect(response).to have_gitlab_http_status(302)
        expect(response.location).to end_with('/users/sign_in')
      end
    end
  end

  describe '#perform_not_found_actions' do
    let(:routable) { create(:project) }

    before do
      sign_in(create(:user))
    end

    it 'performs multiple checks' do
      last_check_called = false
      checks = [proc {}, proc { last_check_called = true }]
      allow(subject).to receive(:not_found_actions).and_return(checks)

      get_routable(routable)

      expect(last_check_called).to eq(true)
    end

    it 'performs checks in the context of the controller' do
      check = lambda { |routable| redirect_to routable }
      allow(subject).to receive(:not_found_actions).and_return([check])

      get_routable(routable)

      expect(response.location).to end_with(routable.to_param)
    end

    it 'skips checks once one has resulted in a render/redirect' do
      first_check = proc { render plain: 'first' }
      second_check = proc { render plain: 'second' }
      allow(subject).to receive(:not_found_actions).and_return([first_check, second_check])

      get_routable(routable)

      expect(response.body).to eq('first')
    end
  end
end
