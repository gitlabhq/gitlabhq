# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', :skip_live_env, :requires_admin, product_group: :tenant_scale do
    describe 'Multiple Cells' do
      # default instance is Cell 1 so the user and project are created in Cell 1
      let!(:user) { create(:user) }
      let!(:project) { create(:project, name: "cell-project-#{SecureRandom.hex(4)}") }

      # set the gdk paths to where you have your gdk folders are
      let(:cell1_gdk_path) { '~/src/gitlab-development-kit/' }
      let(:cell2_gdk_path) { '~/src/gdk2/' }
      let!(:cell1_db) { Runtime::Datastore.new(gdk_folder: cell1_gdk_path) }
      let!(:cell2_db) { Runtime::Datastore.new(gdk_folder: cell2_gdk_path) }

      it(
        'project exists in Cell 1',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/434093',
        only: :local
      ) do
        expect(cell1_db).to have_project(project.name)
      end

      it(
        'project does not exist in Cell 2',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/434092',
        only: :local
      ) do
        expect(cell2_db).not_to have_project(project.name)
      end
    end
  end
end
