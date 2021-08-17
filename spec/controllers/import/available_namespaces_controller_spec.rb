# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::AvailableNamespacesController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "GET index" do
    context "when having group with role never allowed to create projects" do
      using RSpec::Parameterized::TableSyntax

      where(
        role: [:guest, :reporter],
        default_project_creation_access: [::Gitlab::Access::MAINTAINER_PROJECT_ACCESS, ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS],
        group_project_creation_level: [nil, ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS, ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS])

      with_them do
        before do
          stub_application_setting(default_project_creation: default_project_creation_access)
        end

        it "does not include group with access level #{params[:role]} in list" do
          group = create(:group, project_creation_level: group_project_creation_level)
          group.add_user(user, role)
          get :index

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).not_to include({
            'id' => group.id,
            'full_path' => group.full_path
          })
        end
      end
    end

    context "when having group with role always allowed to create projects" do
      using RSpec::Parameterized::TableSyntax

      where(
        role: [:maintainer, :owner],
        default_project_creation_access: [::Gitlab::Access::MAINTAINER_PROJECT_ACCESS, ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS],
        group_project_creation_level: [nil, ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS, ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS])

      with_them do
        before do
          stub_application_setting(default_project_creation: default_project_creation_access)
        end

        it "does not include group with access level #{params[:role]} in list" do
          group = create(:group, project_creation_level: group_project_creation_level)
          group.add_user(user, role)
          get :index

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include({
            'id' => group.id,
            'full_path' => group.full_path
          })
        end
      end
    end

    context "when having developer role" do
      using RSpec::Parameterized::TableSyntax

      where(:default_project_creation_access, :project_creation_level, :is_visible) do
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS           | nil                                                   | false
        ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS           | ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS | true
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS | nil                                                   | true
        ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS | ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS           | false
      end

      with_them do
        before do
          stub_application_setting(default_project_creation: default_project_creation_access)
        end

        it "#{params[:is_visible] ? 'includes' : 'does not include'} group with access level #{params[:role]} in list" do
          group = create(:group, project_creation_level: project_creation_level)
          group.add_user(user, :developer)

          get :index

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).send(is_visible ? 'to' : 'not_to', include({
            'id' => group.id,
            'full_path' => group.full_path
          }))
        end
      end
    end

    context "with an anonymous user" do
      before do
        sign_out(user)
      end

      it "redirects to sign-in page" do
        get :index

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
