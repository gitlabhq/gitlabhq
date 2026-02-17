# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User adds a comment on a commit", :js, feature_category: :source_code_management do
  include Features::NotesHelpers
  include RepoHelpers

  let(:comment_text) { "XML attached" }
  let(:another_comment_text) { "SVG attached" }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:first_comment_position) { sample_commit.line_code.split('_').drop(1) }
  let(:second_comment_position) { sample_commit.del_line_code.split('_').drop(1) }

  where(:rapid_diffs_enabled) do
    [false, true]
  end

  with_them do
    before do
      stub_feature_flags(rapid_diffs_on_commit_show: rapid_diffs_enabled)
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

        page.within(".note, [data-testid='noteable-note-container']") do
          expect(page).to have_content(comment_text).and have_css("gl-emoji")
        end

        page.within(".js-main-target-form") do
          expect(page).to have_field("note[note]", with: "").and have_no_css(".js-md-preview")
        end
      end

      context "when commenting on diff" do
        it "adds a comment" do
          page.within(".diff-file:nth-of-type(1), diff-file:nth-of-type(1)") do |scope|
            # Open a form for a comment and check UI elements are visible and acting as expecting.
            click_diff_line(*first_comment_position)

            expect(scope).to have_field("note[note]")
            expect(scope).to have_button("Cancel")

            # The `Cancel` button closes the current form. The page should not have any open forms after that.
            find_button('Cancel').click

            expect(scope).not_to have_field("note[note]")

            # Try to open the same form twice. There should be only one form opened.
            click_diff_line(*first_comment_position)
            click_diff_line(*first_comment_position)

            expect(scope).to have_field("note[note]", count: 1)

            fill_in("note[note]", with: "#{comment_text} :smile:")

            # Open another form and check we have two forms now (because the first one is filled in).
            click_diff_line(*second_comment_position)

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

            expect(scope).to have_css(".js-md-preview, .js-vue-md-preview", visible: true, count: 2)
                      .and have_content(comment_text)
                      .and have_content(another_comment_text)
                      .and have_xpath("//gl-emoji[@data-name='smile']")

            # Test UI elements, then submit.
            page.within(first_form) do
              expect(find(".js-note-text", visible: false).text).to eq("")
              expect(page).to have_css('.js-md-preview, .js-vue-md-preview')

              click_button("Comment")
            end

            expect(scope).not_to have_field("note[note]")
          end

          # A comment should be added and visible.
          page.within(
            ".diff-file:nth-of-type(1) .note, diff-file:nth-of-type(1) [data-testid='noteable-note-container']"
          ) do |scope|
            expect(scope).to have_content(comment_text).and have_xpath("//gl-emoji[@data-name='smile']")
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

        page.within(
          ".diff-file:nth-of-type(1) form[data-line-code='#{sample_commit.del_line_code}'], diff-file:nth-of-type(1)"
        ) do
          fill_in("note[note]", with: old_comment)
          click_button("Comment")
        end

        page.within(
          [
            ".diff-file:nth-of-type(1) .notes-content.parallel.old",
            "diff-file:nth-of-type(1) [data-testid='noteable-note-container']"
          ].join(',')
        ) do
          expect(page).to have_content(old_comment)
        end

        # Right side.
        click_parallel_diff_line(*first_comment_position)

        page.within(
          ".diff-file:nth-of-type(1) form[data-line-code='#{sample_commit.line_code}'], diff-file:nth-of-type(1)"
        ) do
          fill_in("note[note]", with: new_comment)
          click_button("Comment")
        end

        wait_for_requests

        expect(page).to have_selector(
          ".diff-file:nth-of-type(1) .note, diff-file:nth-of-type(1) [data-testid='noteable-note-container']",
          text: new_comment
        )
      end
    end

    private

    def click_diff_line(old_pos, new_pos)
      find(
        [
          ".line_holder[id$='#{old_pos}_#{new_pos}'] td:nth-of-type(1)",
          "[data-testid='hunk-lines-inline'][id$='_#{old_pos}']"
        ].join(',')
      ).hover
      find(".line_holder[id$='#{old_pos}_#{new_pos}'] button, [data-testid='new_discussion_toggle']").click
    end

    def click_parallel_diff_line(old_pos, new_pos)
      cell = if rapid_diffs_enabled # rubocop:disable RSpec/AvoidConditionalStatements -- Rapid Diffs page has a vastly different markup from a legacy one
               find("[data-testid='hunk-lines-parallel'][id$='_#{old_pos}'] td:first-child")
             else
               find(".line_holder.parallel td[id$='#{old_pos}_#{new_pos}']")
                 .find(:xpath, 'preceding-sibling::*[1][self::td]')
             end

      cell.hover
      find(
        [
          ".line_holder.parallel button[data-line-code$='#{old_pos}_#{new_pos}']",
          "[data-testid='new_discussion_toggle']"
        ].join(',')
      ).click
    end
  end
end
