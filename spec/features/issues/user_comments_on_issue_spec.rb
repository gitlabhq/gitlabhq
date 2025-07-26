# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User comments on issue", :js, feature_category: :team_planning do
  include Features::AutocompleteHelpers
  include Features::NotesHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
    project.add_guest(user)
    sign_in(user)

    visit(project_issue_path(project, issue))
  end

  context "when adding comments" do
    it "adds comment" do
      fill_in 'Add a reply', with: 'XML attached'
      click_button 'Comment'

      within('.work-item-notes') do
        expect(page).to have_content('XML attached')
      end
    end

    it_behaves_like 'rich text editor - common'

    it "adds comment with code block" do
      code_block_content = "Command [1]: /usr/local/bin/git , see [text](doc/text)"

      fill_in 'Add a reply', with: "```\n#{code_block_content}\n```"
      click_button 'Comment'

      within('.work-item-notes') do
        expect(page).to have_css('code', text: code_block_content)
      end
    end

    it 'opens autocomplete menu for quick actions and have `/label` first choice' do
      project.add_maintainer(user)
      create(:label, project: project, title: 'label')

      fill_in 'Add a reply', with: '/l'

      expect(find_highlighted_autocomplete_item).to have_content('/label')
    end

    it "switches back to edit mode if a comment is submitted in preview mode" do
      fill_in 'Add a reply', with: 'just a regular comment'
      click_button 'Preview'

      expect(page).to have_content('Continue editing')

      click_button 'Comment'

      expect(page).not_to have_content('Continue editing')
    end

    context "with a user whose name contains XSS" do
      let_it_be(:xss_user) { create(:user, name: "User <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;") }

      before do
        project.add_guest(xss_user)
      end

      it "escapes username when mentioning user" do
        mention = "@#{xss_user.username} check this out"

        fill_in 'Add a reply', with: mention

        expect { click_button 'Comment' }.not_to raise_error
        expect(page).to have_content(mention)
      end
    end
  end

  context "when editing comments" do
    it "edits comment" do
      fill_in 'Add a reply', with: '# Comment with a header'
      click_button 'Comment'

      within('.work-item-notes') do
        expect(page).to have_content("Comment with a header").and have_no_css("#comment-with-a-header")

        click_button('Edit comment')
        fill_in('Edit comment', with: '+1 Awesome!')
        send_keys [:control, :shift, 'p']

        expect(page).to have_css('.md-preview-holder', text: '+1 Awesome!')

        click_button("Save comment")

        expect(page).not_to have_css('.md-preview-holder')
        expect(page).to have_text('+1 Awesome!')
      end
    end
  end
end
