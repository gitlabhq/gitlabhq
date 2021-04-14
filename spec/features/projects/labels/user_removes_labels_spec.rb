# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User removes labels" do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context "when one label" do
    let!(:label) { create(:label, project: project) }

    before do
      visit(project_labels_path(project))
    end

    it "removes label", :js do
      page.within(".other-labels") do
        page.first(".label-list-item") do
          first('.js-label-options-dropdown').click
          first('.js-delete-label-modal-button').click
        end
      end

      expect(page).to have_content("#{label.title} will be permanently deleted from #{project.name}. This cannot be undone.")

      first(:link, "Delete label").click

      expect(page).to have_content("Label was removed").and have_no_content(label.title)
    end
  end

  context "when many labels", :js do
    before do
      create_list(:label, 3, project: project)

      visit(project_labels_path(project))
    end

    it "removes all labels" do
      loop do
        li = page.first(".label-list-item", minimum: 0)
        break unless li

        li.find('.js-label-options-dropdown').click
        li.click_button("Delete")
        click_link("Delete label")
      end

      expect(page).to have_content("Generate a default set of labels").and have_content("New label")
    end
  end
end
