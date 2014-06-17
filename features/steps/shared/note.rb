module SharedNote
  include Spinach::DSL

  Given 'I delete a comment' do
    find('.note').hover
    find(".js-note-delete").click
  end

  Given 'I haven\'t written any comment text' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: ""
    end
  end

  Given 'I leave a comment like "XML attached"' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "XML attached"
      click_button "Add Comment"
      sleep 0.05
    end
  end

  Given 'I preview a comment text like "Bug fixed :smile:"' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "Bug fixed :smile:"
      find(".js-note-preview-button").trigger("click")
    end
  end

  Given 'I submit the comment' do
    within(".js-main-target-form") do
      click_button "Add Comment"
    end
  end

  Given 'I write a comment like "Nice"' do
    within(".js-main-target-form") do
      fill_in "note[note]", with: "Nice"
    end
  end

  Then 'I should not see a comment saying "XML attached"' do
    page.should_not have_css(".note")
  end

  Then 'I should not see the cancel comment button' do
    within(".js-main-target-form") do
      should_not have_link("Cancel")
    end
  end

  Then 'I should not see the comment preview' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-preview", visible: false)
    end
  end

  Then 'I should not see the comment preview button' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-preview-button", visible: false)
    end
  end

  Then 'I should not see the comment text field' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-text", visible: false)
    end
  end

  Then 'I should see a comment saying "XML attached"' do
    within(".note") do
      page.should have_content("XML attached")
    end
  end

  Then 'I should see an empty comment text field' do
    within(".js-main-target-form") do
      page.should have_field("note[note]", with: "")
    end
  end

  Then 'I should see the comment edit button' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-write-button", visible: true)
    end
  end

  Then 'I should see the comment preview' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-preview", visible: true)
    end
  end

  Then 'I should see the comment preview button' do
    within(".js-main-target-form") do
      page.should have_css(".js-note-preview-button", visible: true)
    end
  end

  Then 'I should see comment "XML attached"' do
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
end
