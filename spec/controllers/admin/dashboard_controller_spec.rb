# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::DashboardController do
  describe '#index' do
    before do
      sign_in(create(:admin))
    end

    it 'retrieves Redis versions' do
      get :index

      expect(assigns[:redis_versions].length).to eq(1)
    end

    context 'with pending_delete projects' do
      render_views

      it 'does not retrieve projects that are pending deletion' do
        project = create(:project)
        pending_delete_project = create(:project, pending_delete: true)

        get :index

        expect(response.body).to match(project.name)
        expect(response.body).not_to match(pending_delete_project.name)
      end
    end
  end
end
