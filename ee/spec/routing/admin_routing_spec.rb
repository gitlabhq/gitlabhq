# frozen_string_literal: true
require 'spec_helper'

describe 'EE-specific admin routing' do
  describe Admin::GeoProjectsController, 'routing' do
    let(:project_registry) { create(:geo_project_registry) }

    it 'routes ../ to #index' do
      expect(get('/admin/geo_projects')).to route_to('admin/geo_projects#index')
    end

    it 'routes ../:id/recheck to #recheck' do
      expect(post("admin/geo_projects/#{project_registry.id}/recheck")).to route_to('admin/geo_projects#recheck', id: project_registry.id.to_s)
    end

    it 'routes ../id:/resync to #resync' do
      expect(post("admin/geo_projects/#{project_registry.id}/resync")).to route_to('admin/geo_projects#resync', id: project_registry.id.to_s)
    end

    it 'routes ../id:/force_redownload to #force_redownload' do
      expect(post("admin/geo_projects/#{project_registry.id}/force_redownload")).to route_to('admin/geo_projects#force_redownload', id: project_registry.id.to_s)
    end
  end
end
