require 'spec_helper'

describe "Lint" do
  before do
    login_as :user
  end

  it "Yaml parsing", js: true do
    content = File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
    visit ci_lint_path 
    fill_in "content", with: content
    click_on "Validate"
    within "table" do
      expect(page).to have_content("Job - rspec")
      expect(page).to have_content("Job - spinach")
      expect(page).to have_content("Deploy Job - staging")
      expect(page).to have_content("Deploy Job - production")
    end
  end

  it "Yaml parsing with error", js: true do
    visit ci_lint_path
    fill_in "content", with: ""
    click_on "Validate"
    expect(page).to have_content("Status: syntax is incorrect")
    expect(page).to have_content("Error: Please provide content of .gitlab-ci.yml")
  end
end
