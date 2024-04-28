# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views issues", feature_category: :team_planning do
  let!(:closed_issue) { create(:closed_issue, project: project) }
  let!(:open_issue1) { create(:issue, project: project) }
  let!(:open_issue2) { create(:issue, project: project) }
  let!(:moved_open_issue) { create(:issue, project: project, moved_to: create(:issue)) }

  let_it_be(:user) { create(:user) }

  shared_examples "opens issue from list" do
    it "opens issue" do
      click_link(issue.title)

      expect(page).to have_content(issue.title)
    end
  end

  shared_examples "open issues" do
    context "open issues" do
      let(:label) { create(:label, project: project, title: "bug") }

      before do
        open_issue1.labels << label

        visit(project_issues_path(project, state: :opened))
      end

      it "shows open issues" do
        expect(page).to have_content(project.name)
          .and have_content(open_issue1.title)
          .and have_content(open_issue2.title)
          .and have_no_content(closed_issue.title)
          .and have_content(moved_open_issue.title)
          .and have_no_content('New list')
      end

      it "opens issues by label" do
        page.within(".issues-list") do
          click_link(label.title)
        end

        expect(page).to have_content(open_issue1.title)
          .and have_no_content(open_issue2.title)
          .and have_no_content(closed_issue.title)
      end

      include_examples "opens issue from list" do
        let(:issue) { open_issue1 }
      end
    end
  end

  shared_examples "closed issues" do
    context "closed issues" do
      before do
        visit(project_issues_path(project, state: :closed))
      end

      it "shows closed issues" do
        expect(page).to have_content(project.name)
          .and have_content(closed_issue.title)
          .and have_no_content(open_issue1.title)
          .and have_no_content(open_issue2.title)
          .and have_no_content(moved_open_issue.title)
          .and have_no_content('New list')
      end

      include_examples "opens issue from list" do
        let(:issue) { closed_issue }
      end
    end
  end

  shared_examples "all issues" do
    context "all issues" do
      before do
        visit(project_issues_path(project, state: :all))
      end

      it "shows all issues" do
        expect(page).to have_content(project.name)
          .and have_content(closed_issue.title)
          .and have_content(open_issue1.title)
          .and have_content(open_issue2.title)
          .and have_content(moved_open_issue.title)
          .and have_no_content('CLOSED (MOVED)')
          .and have_no_content('New list')
      end

      include_examples "opens issue from list" do
        let(:issue) { closed_issue }
      end
    end
  end

  %w[internal public].each do |visibility|
    shared_examples "#{visibility} project" do
      context "when project is #{visibility}" do
        let(:project) { create(:project_empty_repo, :"#{visibility}") }

        include_examples "open issues"
        include_examples "closed issues"
        include_examples "all issues"
      end
    end
  end

  context "when signed in as developer", :js do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    include_examples "public project"
    include_examples "internal project"
  end

  context "when not signed in", :js do
    include_examples "public project"
  end
end
