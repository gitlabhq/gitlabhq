# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin > Admin sees project statistics", feature_category: :groups_and_projects do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    enable_admin_mode!(current_user)

    visit admin_project_path(project)
  end

  context 'when project has statistics' do
    let(:project) { create(:project, :repository) }

    it "shows project statistics" do
      expect(page).to have_content("Storage: 0 B (Repository: 0 B / Wikis: 0 B / Build Artifacts: 0 B / Pipeline Artifacts: 0 B / LFS: 0 B / Snippets: 0 B / Packages: 0 B / Uploads: 0 B)")
    end
  end

  context 'when project has no statistics' do
    let(:project) { create(:project, :repository) { |project| project.statistics.destroy! } }

    it "shows 'Storage: Unknown'" do
      expect(page).to have_content("Storage: Unknown")
    end
  end
end
