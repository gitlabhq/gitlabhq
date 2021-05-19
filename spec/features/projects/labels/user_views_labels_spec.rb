# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views labels" do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }

  let(:label_titles) { %w[bug enhancement feature] }
  let!(:prioritized_label) { create(:label, project: project, title: 'prioritized-label-name', priority: 1) }

  before do
    label_titles.each { |title| create(:label, project: project, title: title) }

    project.add_guest(user)
    sign_in(user)

    visit(project_labels_path(project))
  end

  it "shows all labels" do
    page.within('.prioritized-labels .manage-labels-list') do
      expect(page).to have_content('prioritized-label-name')
    end

    page.within('.other-labels .manage-labels-list') do
      label_titles.each { |title| expect(page).to have_content(title) }
    end
  end
end
