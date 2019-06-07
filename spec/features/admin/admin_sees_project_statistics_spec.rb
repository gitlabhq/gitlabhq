# frozen_string_literal: true

require 'spec_helper'

describe "Admin > Admin sees project statistics" do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)

    visit admin_project_path(project)
  end

  context 'when project has statistics' do
    let(:project) { create(:project, :repository) }

    it "shows project statistics" do
      expect(page).to have_content("Storage: 0 Bytes (0 Bytes repositories, 0 Bytes wikis, 0 Bytes build artifacts, 0 Bytes LFS)")
    end
  end

  context 'when project has no statistics' do
    let(:project) { create(:project, :repository) { |project| project.statistics.destroy } }

    it "shows 'Storage: Unknown'" do
      expect(page).to have_content("Storage: Unknown")
    end
  end
end
