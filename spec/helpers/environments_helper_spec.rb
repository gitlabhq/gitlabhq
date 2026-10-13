# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentsHelper, feature_category: :environment_management do
  include ActionView::Helpers::AssetUrlHelper

  let(:folder_name) { 'env_folder' }
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }

  describe '#environments_folder_list_view_data' do
    subject { helper.environments_folder_list_view_data(project, folder_name) }

    before do
      allow(helper).to receive_messages(current_user: user, can?: true)
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
