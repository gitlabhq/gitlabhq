# frozen_string_literal: true

require "spec_helper"

describe "User comments on issue", :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  before do
    project.add_guest(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  context "when adding comments" do
    it "adds comment" do
      content = "XML attached"
      target_form = ".js-main-target-form"

      add_note(content)

      page.within(".note") do
        expect(page).to have_content(content)
      end

      page.within(target_form) do
        find(".error-alert", visible: false)
      end
    end

    it "adds comment with code block" do
      code_block_content = "Command [1]: /usr/local/bin/git , see [text](doc/text)"
      comment = "```\n#{code_block_content}\n```"

      add_note(comment)

      wait_for_requests

      expect(page.find('pre code').text).to eq code_block_content
    end

    it "renders HTML content as text in Mermaid" do
      html_content = "<img onerror=location=`javascript\\u003aalert\\u0028document.domain\\u0029` src=x>"
      mermaid_content = "graph LR\n  B-->D(#{html_content});"
      comment = "```mermaid\n#{mermaid_content}\n```"

      add_note(comment)

      wait_for_requests

      expect(page.find('svg.mermaid')).to have_content html_content
      within('svg.mermaid') { expect(page).not_to have_selector('img') }
    end

    it 'opens autocomplete menu for quick actions and have `/label` first choice' do
      project.add_maintainer(user)
      create(:label, project: project, title: 'label')

      page.within '.timeline-content-form' do
        find('#note-body').native.send_keys('/l')
      end

      wait_for_requests

      expect(page).to have_selector('.atwho-container')

      page.within '.atwho-container #at-view-commands' do
        expect(find('li', match: :first)).to have_content('/label')
      end
    end
  end

  context "when editing comments" do
    it "edits comment" do
      add_note("# Comment with a header")

      page.within(".note-body > .note-text") do
        expect(page).to have_content("Comment with a header").and have_no_css("#comment-with-a-header")
      end

      page.within(".main-notes-list") do
        note = find(".note")

        note.hover
        note.find(".js-note-edit").click
      end

      expect(page).to have_css(".current-note-edit-form textarea")

      comment = "+1 Awesome!"

      page.within(".current-note-edit-form") do
        fill_in("note[note]", with: comment)
        find('textarea').send_keys [:control, :shift, 'p']
        expect(page).to have_selector('.current-note-edit-form .md-preview-holder')
        expect(page.find('.current-note-edit-form .md-preview-holder p')).to have_content(comment)
      end

      expect(page).to have_selector('.new-note .note-textarea')

      page.within(".current-note-edit-form") do
        click_button("Save comment")
      end

      wait_for_requests

      page.within(".note") do
        expect(page).to have_content(comment)
      end
    end
  end
end
