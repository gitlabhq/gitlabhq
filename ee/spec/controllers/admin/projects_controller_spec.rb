# frozen_string_literal: true

require 'spec_helper'

describe Admin::ProjectsController do
  include EE::GeoHelpers

  let!(:project_registry) { create(:geo_project_registry) }
  let(:project) { project_registry.project }

  before do
    sign_in(create(:admin))
  end

  describe 'GET /projects/:id' do
    subject { get :show, namespace_id: project.namespace.path, id: project.path }

    render_views

    it 'includes Geo Status widget partial' do
      expect(subject).to have_gitlab_http_status(200)
      expect(subject.body).to match(project.name)
      expect(subject).to render_template(partial: 'admin/projects/_geo_status_widget')
    end

    context 'when Geo is enabled and is a secondary node' do
      before do
        stub_current_geo_node(create(:geo_node))
      end

      it 'renders Geo Status widget' do
        expect(subject.body).to match('Geo Status')
      end
    end

    context 'without Geo enabled' do
      it 'doesnt render Geo Status widget' do
        expect(subject.body).not_to match('Geo Status')
      end
    end
  end
end
