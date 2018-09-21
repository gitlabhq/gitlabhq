# frozen_string_literal: true
require 'spec_helper'

describe 'EE-specific admin routing' do
  describe Admin::Geo::ProjectsController, 'routing' do
    let(:project_registry) { create(:geo_project_registry) }

    it 'routes / to #index' do
      expect(get('/admin/geo/projects')).to route_to('admin/geo/projects#index')
    end

    it 'routes /:id/recheck to #recheck' do
      expect(post("admin/geo/projects/#{project_registry.id}/recheck")).to route_to('admin/geo/projects#recheck', id: project_registry.to_param)
    end

    it 'routes /id:/resync to #resync' do
      expect(post("admin/geo/projects/#{project_registry.id}/resync")).to route_to('admin/geo/projects#resync', id: project_registry.to_param)
    end

    it 'routes /id:/force_redownload to #force_redownload' do
      expect(post("admin/geo/projects/#{project_registry.id}/force_redownload")).to route_to('admin/geo/projects#force_redownload', id: project_registry.to_param)
    end
  end

  describe Admin::Geo::NodesController, 'routing' do
    let(:geo_node) { create(:geo_node) }

    it 'routes / to #index' do
      expect(get('/admin/geo/nodes')).to route_to('admin/geo/nodes#index')
    end

    it 'routes /new to #new' do
      expect(get('/admin/geo/nodes/new')).to route_to('admin/geo/nodes#new')
    end

    it 'routes /edit to #edit' do
      expect(get("/admin/geo/nodes/#{geo_node.id}/edit")).to route_to('admin/geo/nodes#edit', id: geo_node.to_param)
    end

    it 'routes post / to #create' do
      expect(post('/admin/geo/nodes/')).to route_to('admin/geo/nodes#create')
    end

    it 'routes patch /:id to #update' do
      expect(patch("/admin/geo/nodes/#{geo_node.id}")).to route_to('admin/geo/nodes#update', id: geo_node.to_param)
    end
  end
end
