# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Maintainer manages access requests', feature_category: :groups_and_projects do
  it_behaves_like 'Maintainer manages access requests' do
    let(:entity) { create(:project, :public, :with_namespace_settings) }
    let(:members_page_path) { project_project_members_path(entity) }
  end
end
