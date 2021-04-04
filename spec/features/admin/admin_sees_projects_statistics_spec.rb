# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin > Admin sees projects statistics" do
  let(:current_user) { create(:admin) }

  before do
    create(:project, :repository)
    create(:project, :repository) { |project| project.statistics.destroy! }

    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)

    visit admin_projects_path
  end

  it "shows project statistics for projects that have them" do
    expect(page.all('.stats').map(&:text)).to contain_exactly("0 Bytes", "Unknown")
  end
end
