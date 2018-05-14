require "spec_helper"

describe "User removes labels" do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context "when one label" do
    let!(:label) { create(:label, project: project) }

    before do
      visit(project_labels_path(project))
    end

    it "removes label" do
      page.within(".labels") do
        page.first(".label-list-item") do
          first(".remove-row").click
          first(:link, "Delete label").click
        end
      end

      expect(page).to have_content("Label was removed").and have_no_content(label.title)
    end
  end

  context "when many labels", :js do
    before do
      create_list(:label, 3, project: project)

      visit(project_labels_path(project))
    end

    it "removes all labels" do
      page.within(".labels") do
        loop do
          li = page.first(".label-list-item")
          break unless li

          li.click_link("Delete")
          click_link("Delete label")
        end

        expect(page).to have_content("Generate a default set of labels").and have_content("New label")
      end
    end
  end
end
