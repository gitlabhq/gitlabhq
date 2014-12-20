module SharedDiffNote
  include Spinach::DSL
  include RepoHelpers

  step 'I cancel the diff comment' do
    within(diff_file_selector) do
      find(".js-close-discussion-note-form").click
    end
  end

  step 'I delete a diff comment' do
    find('.note').hover
    find(".js-note-delete").click
  end

  step 'I haven\'t written any diff comment text' do
    within(diff_file_selector) do
      fill_in "note[note]", with: ""
    end
  end

  step 'I leave a diff comment like "Typo, please fix"' do
    click_diff_line(sample_commit.line_code)
    within("#{diff_file_selector} form[rel$='#{sample_commit.line_code}']") do
      fill_in "note[note]", with: "Typo, please fix"
      find(".js-comment-button").trigger("click")
      sleep 0.05
    end
  end

  step 'I preview a diff comment text like "Should fix it :smile:"' do
    click_diff_line(sample_commit.line_code)
    within("#{diff_file_selector} form[rel$='#{sample_commit.line_code}']") do
      fill_in "note[note]", with: "Should fix it :smile:"
      find('.js-md-preview-button').click
    end
  end

  step 'I preview another diff comment text like "DRY this up"' do
    click_diff_line(sample_commit.del_line_code)

    within("#{diff_file_selector} form[rel$='#{sample_commit.del_line_code}']") do
      fill_in "note[note]", with: "DRY this up"
      find('.js-md-preview-button').click
    end
  end

  step 'I open a diff comment form' do
    click_diff_line(sample_commit.line_code)
  end

  step 'I open another diff comment form' do
    click_diff_line(sample_commit.del_line_code)
  end

  step 'I write a diff comment like ":-1: I don\'t like this"' do
    within(diff_file_selector) do
      fill_in "note[note]", with: ":-1: I don\'t like this"
    end
  end

  step 'I submit the diff comment' do
    within(diff_file_selector) do
      click_button("Add Comment")
    end
  end

  step 'I should not see the diff comment form' do
    within(diff_file_selector) do
      page.should_not have_css("form.new_note")
    end
  end

  step 'The diff comment preview tab should say there is nothing to do' do
    within(diff_file_selector) do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_content('Nothing to preview.')
    end
  end

  step 'I should not see the diff comment text field' do
    within(diff_file_selector) do
      page.should have_css(".js-note-text", visible: false)
    end
  end

  step 'I should only see one diff form' do
    within(diff_file_selector) do
      page.should have_css("form.new_note", count: 1)
    end
  end

  step 'I should see a diff comment form with ":-1: I don\'t like this"' do
    within(diff_file_selector) do
      page.should have_field("note[note]", with: ":-1: I don\'t like this")
    end
  end

  step 'I should see a diff comment saying "Typo, please fix"' do
    within("#{diff_file_selector} .note") do
      page.should have_content("Typo, please fix")
    end
  end

  step 'I should see a discussion reply button' do
    within(diff_file_selector) do
      page.should have_button('Reply')
    end
  end

  step 'I should see a temporary diff comment form' do
    within(diff_file_selector) do
      page.should have_css(".js-temp-notes-holder form.new_note")
    end
  end

  step 'I should see add a diff comment button' do
    page.should have_css(".js-add-diff-note-button", visible: false)
  end

  step 'I should see an empty diff comment form' do
    within(diff_file_selector) do
      page.should have_field("note[note]", with: "")
    end
  end

  step 'I should see the cancel comment button' do
    within("#{diff_file_selector} form") do
      page.should have_css(".js-close-discussion-note-form", text: "Cancel")
    end
  end

  step 'I should see the diff comment preview' do
    within("#{diff_file_selector} form") do
      expect(page).to have_css('.js-md-preview', visible: true)
    end
  end

  step 'I should see the diff comment write tab' do
    within(diff_file_selector) do
      expect(page).to have_css('.js-md-write-button', visible: true)
    end
  end

  step 'The diff comment preview tab should display rendered Markdown' do
    within(diff_file_selector) do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_css('img.emoji', visible: true)
    end
  end

  step 'I should see two separate previews' do
    within(diff_file_selector) do
      expect(page).to have_css('.js-md-preview', visible: true, count: 2)
      expect(page).to have_content('Should fix it')
      expect(page).to have_content('DRY this up')
    end
  end

  def diff_file_selector
    ".diff-file:nth-of-type(1)"
  end

  def click_diff_line(code)
    find("button[data-line-code='#{code}']").click
  end
end
