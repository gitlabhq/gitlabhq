# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin > Admin sees project statistics" do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)

    visit admin_project_path(project)
  end

  context 'when project has statistics' do
    let(:project) { create(:project, :repository) }

    it "shows project statistics" do
      expect(page).to have_content("Storage: 0 Bytes (Repository: 0 Bytes / Wikis: 0 Bytes / Build Artifacts: 0 Bytes / LFS: 0 Bytes / Snippets: 0 Bytes / Packages: 0 Bytes / Uploads: 0 Bytes)")
    end
  end

  context 'when project has no statistics' do
    let(:project) { create(:project, :repository) { |project| project.statistics.destroy! } }

    it "shows 'Storage: Unknown'" do
      expect(page).to have_content("Storage: Unknown")
    end
  end
end
