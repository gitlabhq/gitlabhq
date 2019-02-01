# frozen_string_literal: true

require "spec_helper"

describe "User views labels" do
  set(:project) { create(:project_empty_repo, :public) }
  set(:user) { create(:user) }

  let(:label_titles) { %w[bug enhancement feature] }

  before do
    label_titles.each { |title| create(:label, project: project, title: title) }

    project.add_guest(user)
    sign_in(user)

    visit(project_labels_path(project))
  end

  it "shows all labels" do
    page.within('.other-labels .manage-labels-list') do
      label_titles.each { |title| expect(page).to have_content(title) }
    end
  end
end
