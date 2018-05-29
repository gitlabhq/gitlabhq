require "spec_helper"

describe "User views labels" do
  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { create(:user) }

  LABEL_TITLES = %w[bug enhancement feature].freeze
  PRIORITIZED_LABELS_TITLES = %w[p1 p2 p3].freeze

  before do
    LABEL_TITLES.each { |title| create(:label, project: project, title: title) }
    PRIORITIZED_LABELS_TITLES.each { |title| create(:label, project: project, title: title, priority: rand(3)) }

    project.add_guest(user)
    sign_in(user)

    visit(project_labels_path(project))
  end

  it "shows all labels without priority" do
    page.within('.other-labels .manage-labels-list') do
      LABEL_TITLES.each { |title| expect(page).to have_content(title) }
    end
  end

  it "shows all prioritized labels" do
    expect(page).not_to have_selector('.js-prioritized-labels')

    page.within('.prioritized-labels .manage-labels-list') do
      PRIORITIZED_LABELS_TITLES.each { |title| expect(page).to have_content(title) }
    end
  end
end
