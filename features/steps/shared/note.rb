module SharedNote
  include Spinach::DSL

  step 'I delete a comment' do
    find('.note').hover
    find(".js-note-delete").click
  end

  step 'I haven\'t written any comment text' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: ""
    end
  end

  step 'I leave a comment like "XML attached"' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "XML attached"
      click_button "Add Comment"
      sleep 0.05
    end
  end

  step 'I preview a comment text like "Bug fixed :smile:"' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "Bug fixed :smile:"
      find('.js-md-preview-button').click
    end
  end

  step 'I submit the comment' do
    within(".js-main-target-form") do
      click_button "Add Comment"
    end
  end

  step 'I write a comment like ":+1: Nice"' do
    within(".js-main-target-form") do
      fill_in 'note[note]', with: ':+1: Nice'
    end
  end

  step 'I should not see a comment saying "XML attached"' do
    page.should_not have_css(".note")
  end

  step 'I should not see the cancel comment button' do
    within(".js-main-target-form") do
      should_not have_link("Cancel")
    end
  end

  step 'I should not see the comment preview' do
    within(".js-main-target-form") do
      expect(find('.js-md-preview')).not_to be_visible
    end
  end

  step 'The comment preview tab should say there is nothing to do' do
    within(".js-main-target-form") do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_content('Nothing to preview.')
    end
  end

  step 'I should not see the comment text field' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-text", visible: false)
    end
  end

  step 'I should see a comment saying "XML attached"' do
    within(".note") do
      page.should have_content("XML attached")
    end
  end

  step 'I should see an empty comment text field' do
    within(".js-main-target-form") do
      page.should have_field("note[note]", with: "")
    end
  end

  step 'I should see the comment write tab' do
    within(".js-main-target-form") do
      expect(page).to have_css('.js-md-write-button', visible: true)
    end
  end

  step 'The comment preview tab should be display rendered Markdown' do
    within(".js-main-target-form") do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_css('img.emoji', visible: true)
    end
  end

  step 'I should see the comment preview' do
    within(".js-main-target-form") do
      expect(page).to have_css('.js-md-preview', visible: true)
    end
  end

  step 'I should see comment "XML attached"' do
    within(".note") do
      page.should have_content("XML attached")
    end
  end

  # Markdown

  step 'I leave a comment with a header containing "Comment with a header"' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "# Comment with a header"
      click_button "Add Comment"
      sleep 0.05
    end
  end

  step 'The comment with the header should not have an ID' do
    within(".note-text") do
      page.should     have_content("Comment with a header")
      page.should_not have_css("#comment-with-a-header")
    end
  end

  step 'I leave a comment with task markdown' do
    within('.js-main-target-form') do
      fill_in 'note[note]', with: '* [x] Task item'
      click_button 'Add Comment'
      sleep 0.05
    end
  end

  step 'I should not see task checkboxes in the comment' do
    expect(page).not_to have_selector(
      'li.note div.timeline-content input[type="checkbox"]'
    )
  end
end
