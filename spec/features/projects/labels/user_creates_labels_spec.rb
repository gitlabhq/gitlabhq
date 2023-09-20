# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User creates labels", feature_category: :team_planning do
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:user) { create(:user) }

  shared_examples_for "label creation" do
    it "creates new label" do
      title = "bug"

      create_label(title)

      page.within(".other-labels .manage-labels-list") do
        expect(page).to have_content(title)
      end
    end
  end

  context "in project" do
    before do
      project.add_maintainer(user)
      sign_in(user)

      visit(new_project_label_path(project))
    end

    context "when data is valid" do
      include_examples "label creation"
    end

    context "when data is invalid" do
      context "when title is invalid" do
        it "shows error message" do
          create_label("")

          page.within(".label-form") do
            expect(page).to have_content("Title can't be blank")
          end
        end
      end

      context "when color is invalid" do
        it "shows error message" do
          create_label("feature", "#12")

          page.within(".label-form") do
            expect(page).to have_content("Color must be a valid color code")
          end
        end
      end
    end

    context "when label already exists" do
      let!(:label) { create(:label, project: project) }

      it "shows error message" do
        create_label(label.title)

        page.within(".label-form") do
          expect(page).to have_content("Title has already been taken")
        end
      end
    end

    it_behaves_like "lock_on_merge when creating labels"
  end

  context "in another project" do
    let_it_be(:another_project) { create(:project_empty_repo, :public) }

    before do
      create(:label, project: project, title: "bug") # Create label for `project` (not `another_project`) project.

      another_project.add_maintainer(user)
      sign_in(user)

      visit(new_project_label_path(another_project))
    end

    include_examples "label creation"
  end

  private

  def create_label(title, color = "#F95610")
    fill_in("Title", with: title)
    fill_in("Background color", with: color)
    click_button("Create label")
  end
end
