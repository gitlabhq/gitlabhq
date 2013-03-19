require 'spec_helper'

describe "On the project wall", js: true do
  let!(:project) { create(:project) }

  before do
    login_as :user
    project.team << [@user, :master]
    visit project_wall_path(project)
  end

  subject { page }

  describe "the note form" do
    it { should have_css(".wall-note-form", visible: true, count: 1) }
    it { find(".wall-note-form input[type=submit]").value.should == "Add Comment" }
    it { within(".wall-note-form") { should have_unchecked_field("Notify team via email") } }

    describe "with text" do
      before do
        within(".wall-note-form") do
          fill_in "note[note]", with: "This is awesome"
        end
      end

      it { within(".wall-note-form") { should_not have_css(".js-comment-button[disabled]") } }
    end
  end

  describe "when posting a note" do
    before do
      within(".wall-note-form") do
        fill_in "note[note]", with: "This is awsome!"
        click_button "Add Comment"
      end
    end

    it { should have_content("This is awsome!") }
    it { within(".wall-note-form") { should have_no_field("note[note]", with: "This is awesome!") } }
  end
end
