# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::AvailableNamespacesController do
  let_it_be(:user) { create(:user) }
  let_it_be(:manageable_groups) { [create(:group), create(:group)] }

  before do
    sign_in(user)
    manageable_groups.each { |group| group.add_maintainer(user) }
  end

  describe "GET index" do
    it "returns list of available namespaces" do
      unrelated_group = create(:group)

      get :index

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_kind_of(Array)

      response_ids = json_response.map { |n| n["id"] }

      expect(response_ids).not_to include(unrelated_group.id)
      expect(response_ids).to contain_exactly(*manageable_groups.map(&:id))
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
