# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin > Admin sees projects statistics", feature_category: :groups_and_projects do
  let(:current_user) { create(:admin) }

  before do
    # The project statistics isn't available when `admin_projects_vue` flag is enabled. This will be added
    # later on in https://gitlab.com/gitlab-org/gitlab/-/issues/541504
    stub_feature_flags(admin_projects_vue: false)

    create(:project, :repository)
    create(:project, :repository) { |project| project.statistics.destroy! }

    sign_in(current_user)
    enable_admin_mode!(current_user)

    visit admin_projects_path
  end

  it "shows project statistics for projects that have them" do
    expect(page.all('.stats').map(&:text)).to contain_exactly("0 B", "Unknown")
  end
end
