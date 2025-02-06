# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentsHelper, feature_category: :environment_management do
  include ActionView::Helpers::AssetUrlHelper

  folder_name = 'env_folder'
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, :with_folders, folder: folder_name, project: project) }

  describe '#environments_folder_list_view_data' do
    subject { helper.environments_folder_list_view_data(project, folder_name) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'returns folder related data' do
      expect(subject).to include(
        'endpoint' => folder_project_environments_path(project, folder_name, format: :json),
        'can_read_environment' => 'true',
        'project_path' => project.full_path,
        'folder_name' => folder_name,
        'help_page_path' => '/help/ci/environments/_index.md'
      )
    end
  end
end
