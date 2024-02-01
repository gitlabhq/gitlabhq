# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', :skip_live_env, :requires_admin, product_group: :tenant_scale do
    describe 'Multiple Cells' do
      # set the gdk paths to where you have your gdk folders are
      let(:cell1_gdk_path) { ENV.fetch('CELL1_GDK_PATH', '~/src/gitlab-development-kit/') }
      let(:cell2_gdk_path) { ENV.fetch('CELL2_GDK_PATH', '~/src/gdk2/') }
      let!(:cell1_db) { Runtime::Datastore.new(gdk_folder: cell1_gdk_path) }
      let!(:cell2_db) { Runtime::Datastore.new(gdk_folder: cell2_gdk_path) }

      it(
        'projects are unique between cells',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/434090',
        only: :local
      ) do
        cell1_projects = cell1_db.projects
        cell2_projects = cell2_db.projects

        expect(cell1_projects & cell2_projects).to be_empty
      end

      it(
        'namespaces are unique between cells',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/434091',
        only: :local
      ) do
        cell1_namespaces = cell1_db.namespaces
        cell2_namespaces = cell2_db.namespaces

        expect(cell1_namespaces & cell2_namespaces).to be_empty
      end
    end
  end
end
