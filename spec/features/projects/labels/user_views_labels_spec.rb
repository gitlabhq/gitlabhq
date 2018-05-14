require "spec_helper"

describe "User views labels" do
  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { create(:user) }

  LABEL_TITLES = %w[bug enhancement feature].freeze

  before do
    LABEL_TITLES.each { |title| create(:label, project: project, title: title) }

    project.add_guest(user)
    sign_in(user)

    visit(project_labels_path(project))
  end

  it "shows all labels" do
    page.within('.other-labels .manage-labels-list') do
      LABEL_TITLES.each { |title| expect(page).to have_content(title) }
    end
  end
end
