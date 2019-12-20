# frozen_string_literal: true

require 'spec_helper'

describe ControllerWithCrossProjectAccessCheck do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  render_views

  context 'When reading cross project is not allowed' do
    before do
      allow(Ability).to receive(:allowed).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(user, :read_cross_project, :global)
                          .and_return(false)
    end

    describe '#requires_cross_project_access' do
      controller(ApplicationController) do
        # `described_class` is not available in this context
        include ControllerWithCrossProjectAccessCheck

        requires_cross_project_access :index, show: false,
                                              unless: -> { unless_condition },
                                              if: -> { if_condition }

        def index
          head :ok
        end

        def show
          head :ok
        end

        def unless_condition
          false
        end

        def if_condition
          true
        end
      end

      it 'renders a 403 with trying to access a cross project page' do
        message = "This page is unavailable because you are not allowed to read "\
                  "information across multiple projects."

        get :index

        expect(response).to have_gitlab_http_status(403)
        expect(response.body).to match(/#{message}/)
      end

      it 'is skipped when the `if` condition returns false' do
        expect(controller).to receive(:if_condition).and_return(false)

        get :index

        expect(response).to have_gitlab_http_status(200)
      end

      it 'is skipped when the `unless` condition returns true' do
        expect(controller).to receive(:unless_condition).and_return(true)

        get :index

        expect(response).to have_gitlab_http_status(200)
      end

      it 'correctly renders an action that does not require cross project access' do
        get :show, params: { id: 'nothing' }

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe '#skip_cross_project_access_check' do
      controller(ApplicationController) do
        # `described_class` is not available in this context
        include ControllerWithCrossProjectAccessCheck

        requires_cross_project_access

        skip_cross_project_access_check index: true, show: false,
                                        unless: -> { unless_condition },
                                        if: -> { if_condition }

        def index
          head :ok
        end

        def show
          head :ok
        end

        def edit
          head :ok
        end

        def unless_condition
          false
        end

        def if_condition
          true
        end
      end

      it 'renders a success when the check is skipped' do
        get :index

        expect(response).to have_gitlab_http_status(200)
      end

      it 'is executed when the `if` condition returns false' do
        expect(controller).to receive(:if_condition).and_return(false)

        get :index

        expect(response).to have_gitlab_http_status(403)
      end

      it 'is executed when the `unless` condition returns true' do
        expect(controller).to receive(:unless_condition).and_return(true)

        get :index

        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not skip the check on an action that is not skipped' do
        get :show, params: { id: 'hello' }

        expect(response).to have_gitlab_http_status(403)
      end

      it 'does not skip the check on an action that was not defined to skip' do
        get :edit, params: { id: 'hello' }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
