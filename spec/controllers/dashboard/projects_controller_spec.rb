# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::ProjectsController, :aggregate_failures, feature_category: :groups_and_projects do
  include ExternalAuthorizationServiceHelpers

  let_it_be(:user) { create(:user) }

  describe '#index' do
    context 'user logged in' do
      let_it_be(:project) { create(:project, name: 'Project 1') }
      let_it_be(:project2) { create(:project, name: 'Project Two') }

      let(:projects) { [project, project2] }

      before_all do
        project.add_developer(user)
        project2.add_developer(user)
        user.toggle_star(project2)
      end

      before do
        sign_in(user)
      end

      context 'external authorization' do
        it 'works when the external authorization service is enabled' do
          enable_external_authorization_service_check

          get :index

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with redirects' do
        it 'redirects ?personal=true to /personal' do
          get :index, params: { personal: true }

          expect(response).to redirect_to(personal_dashboard_projects_path)
        end

        it 'redirects ?archived=only to /inactive' do
          get :index, params: { archived: 'only' }

          expect(response).to redirect_to(inactive_dashboard_projects_path)
        end
      end
    end
  end

  context 'atom requests' do
    before do
      sign_in(user)
    end

    describe '#index' do
      let_it_be(:projects) { create_list(:project, 2, creator: user) }

      context 'project pagination' do
        before do
          allow(Kaminari.config).to receive(:default_per_page).and_return(1)

          projects.each do |project|
            project.add_developer(user)
          end
        end

        it 'does not paginate projects, even if normally restricted by pagination' do
          get :index, format: :atom

          expect(assigns(:events).count).to eq(2)
        end
      end

      describe 'rendering' do
        include DesignManagementTestHelpers
        render_views

        let(:project) { projects.first }
        let!(:design_event) { create(:design_event, project: project) }
        let!(:wiki_page_event) { create(:wiki_page_event, project: project) }
        let!(:issue_event) { create(:closed_issue_event, project: project) }
        let!(:push_event) do
          create(:push_event, project: project).tap do |event|
            create(:push_event_payload, event: event, ref_count: 2, ref: nil, ref_type: :tag, commit_count: 0, action: :pushed)
          end
        end

        let(:design) { design_event.design }
        let(:wiki_page) { wiki_page_event.wiki_page }
        let(:issue) { issue_event.issue }

        before do
          enable_design_management
          project.add_developer(user)
        end

        it 'renders all kinds of event without error' do
          get :index, format: :atom

          expect(assigns(:events)).to include(design_event, wiki_page_event, issue_event, push_event)
          expect(response).to render_template('dashboard/projects/index')
          expect(response.body).to include(
            "pushed to project",
            "added design #{design.to_reference}",
            "created wiki page #{wiki_page.title}",
            "joined project #{project.full_name}",
            "closed issue #{issue.to_reference}"
          )
        end

        context 'with deleted project' do
          let(:pending_deleted_project) { projects.last.tap { |p| p.update!(pending_delete: true) } }

          before do
            pending_deleted_project.add_developer(user)
          end

          it 'does not display deleted project' do
            get :index, format: :atom

            expect(response.body).not_to include(pending_deleted_project.full_name)
            expect(response.body).to include(project.full_name)
          end
        end
      end
    end
  end
end
