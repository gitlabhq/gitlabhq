# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User adds a comment on a commit", :js, feature_category: :source_code_management do
  include Features::NotesHelpers
  include RepoHelpers
  include RapidDiffsHelpers

  let(:comment_text) { "XML attached" }
  let(:another_comment_text) { "SVG attached" }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:first_comment_position) { sample_commit.line_code.split('_').drop(1) }
  let(:second_comment_position) { sample_commit.del_line_code.split('_').drop(1) }

  before do
    stub_feature_flags(page_breadcrumbs_in_top_bar: false)
    sign_in(user)
    project.add_developer(user)
  end

  context "inline view" do
    before do
      visit(project_commit_path(project, sample_commit.id))
    end

    it "adds a comment" do
      page.within(".js-main-target-form") do
        expect(page).not_to have_link("Cancel")

        emoji = ":+1:"

        fill_in("note[note]", with: "#{comment_text} #{emoji}")

        # Check on `Preview` tab
        click_button("Preview")

        expect(find(".js-md-preview, .js-vue-md-preview")).to have_content(comment_text).and have_css("gl-emoji")
        expect(page).not_to have_css(".js-note-text")

        # Check on the `Write` tab
        click_button("Continue editing")

        expect(page).to have_field("note[note]", with: "#{comment_text} #{emoji}")

        # Submit comment from the `Preview` tab to get rid of a separate `it` block
        # which would specially test if everything gets cleared from the note form.
        click_button("Preview")
        click_button("Comment")
      end

      wait_for_requests

      within_testid('noteable-note-container') do
        expect(page).to have_content(comment_text).and have_css("gl-emoji")
      end

      page.within(".js-main-target-form") do
        expect(page).to have_field("note[note]", with: "").and have_no_css(".js-md-preview")
      end
    end

    context "when commenting on diff" do
      it "adds a comment" do
        within(first_diff_file) do |scope|
          # Open a form for a comment and check UI elements are visible and acting as expecting.
          click_inline_diff_line(*first_comment_position)

          expect(scope).to have_field("note[note]")
          expect(scope).to have_button("Cancel")

          # The `Cancel` button closes the current form. The page should not have any open forms after that.
          find_button('Cancel').click

          expect(scope).not_to have_field("note[note]")

          # Try to open the same form twice. There should be only one form opened.
          click_inline_diff_line(*first_comment_position)
          click_inline_diff_line(*first_comment_position)

          expect(scope).to have_field("note[note]", count: 1)

          fill_in("note[note]", with: "#{comment_text} :smile:")

          # Open another form and check we have two forms now (because the first one is filled in).
          click_inline_diff_line(*second_comment_position)

          expect(scope).to have_field("note[note]", with: "#{comment_text} :smile:")
                    .and have_field("note[note]", with: "")

          first_form = find_field('note[note]', with: "#{comment_text} :smile:").ancestor('form')
          page.within(first_form) do
            click_button("Preview")
          end

          second_form = find_field('note[note]', with: "").ancestor('form')
          page.within(second_form) do
            fill_in("note[note]", with: another_comment_text)
            click_button("Preview")
          end

          expect(scope).to have_css(".js-md-preview, .js-vue-md-preview", visible: :visible, count: 2)
                    .and have_content(comment_text)
                    .and have_content(another_comment_text)
                    .and have_xpath("//gl-emoji[@data-name='smile']")

          # Test UI elements, then submit.
          page.within(first_form) do
            expect(find(".js-note-text", visible: :hidden).text).to eq("")
            expect(page).to have_css('.js-md-preview, .js-vue-md-preview')

            click_button("Comment")
          end

          expect(scope).not_to have_field("note[note]")
        end

        # A comment should be added and visible.
        within(first_diff_file) do
          expect(page).to have_testid('noteable-note-container', text: comment_text)
          expect(page).to have_xpath("//gl-emoji[@data-name='smile']")
        end
      end
    end
  end

  context "side-by-side view" do
    before do
      visit(project_commit_path(project, sample_commit.id, view: "parallel"))
    end

    it "adds a comment" do
      new_comment = "New comment"
      old_comment = "Old comment"

      # Left side.
      click_parallel_diff_line(*second_comment_position)

      within(first_diff_file) do
        fill_in("note[note]", with: old_comment)
        click_button("Comment")
      end

      within(first_diff_file) do
        expect(page).to have_content(old_comment)
      end

      # Right side.
      click_parallel_diff_line(*first_comment_position)

      within(first_diff_file) do
        fill_in("note[note]", with: new_comment)
        click_button("Comment")
      end

      wait_for_requests

      within(first_diff_file) do
        expect(page).to have_testid('noteable-note-container', text: new_comment)
      end
    end
  end

  private

  def first_diff_file
    find_by_testid('rd-diff-file', match: :first)
  end

  def click_inline_diff_line(old_pos, _new_pos)
    click_rapid_diffs_line("[data-testid='hunk-lines-inline'][id$='_#{old_pos}']")
  end

  def click_parallel_diff_line(old_pos, _new_pos)
    click_rapid_diffs_line("[data-testid='hunk-lines-parallel'][id$='_#{old_pos}']")
  end
end
