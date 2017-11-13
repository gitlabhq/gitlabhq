module SharedDiffNote
  include Spinach::DSL
  include RepoHelpers
  include WaitForRequests

  after do
    wait_for_requests if javascript_test?
  end

  step 'I cancel the diff comment' do
    page.within(diff_file_selector) do
      find(".js-close-discussion-note-form").click
    end
  end

  step 'I delete a diff comment' do
    find('.note').hover
    find(".js-note-delete").click
  end

  step 'I haven\'t written any diff comment text' do
    page.within(diff_file_selector) do
      fill_in "note[note]", with: ""
    end
  end

  step 'I leave a diff comment like "Typo, please fix"' do
    page.within(diff_file_selector) do
      click_diff_line(sample_commit.line_code)

      page.within("form[data-line-code='#{sample_commit.line_code}']") do
        fill_in "note[note]", with: "Typo, please fix"
        find(".js-comment-button").click
      end
    end
  end

  step 'I leave a diff comment in a parallel view on the left side like "Old comment"' do
    click_parallel_diff_line(sample_commit.del_line_code, 'old')
    page.within("#{diff_file_selector} form[data-line-code='#{sample_commit.del_line_code}']") do
      fill_in "note[note]", with: "Old comment"
      find(".js-comment-button").click
    end
  end

  step 'I leave a diff comment in a parallel view on the right side like "New comment"' do
    click_parallel_diff_line(sample_commit.line_code, 'new')
    page.within("#{diff_file_selector} form[data-line-code='#{sample_commit.line_code}']") do
      fill_in "note[note]", with: "New comment"
      find(".js-comment-button").click
    end
  end

  step 'I preview a diff comment text like "Should fix it :smile:"' do
    page.within(diff_file_selector) do
      click_diff_line(sample_commit.line_code)

      page.within("form[data-line-code='#{sample_commit.line_code}']") do
        fill_in "note[note]", with: "Should fix it :smile:"
        find('.js-md-preview-button').click
      end
    end
  end

  step 'I preview another diff comment text like "DRY this up"' do
    page.within(diff_file_selector) do
      click_diff_line(sample_commit.del_line_code)

      page.within("form[data-line-code='#{sample_commit.del_line_code}']") do
        fill_in "note[note]", with: "DRY this up"
        find('.js-md-preview-button').click
      end
    end
  end

  step 'I open a diff comment form' do
    page.within(diff_file_selector) do
      click_diff_line(sample_commit.line_code)
    end
  end

  step 'I open another diff comment form' do
    page.within(diff_file_selector) do
      click_diff_line(sample_commit.del_line_code)
    end
  end

  step 'I write a diff comment like ":-1: I don\'t like this"' do
    page.within(diff_file_selector) do
      fill_in "note[note]", with: ":-1: I don\'t like this"
    end
  end

  step 'I write a diff comment like ":smile:"' do
    page.within(diff_file_selector) do
      click_diff_line(sample_commit.line_code)

      page.within("form[data-line-code='#{sample_commit.line_code}']") do
        fill_in 'note[note]', with: ':smile:'
        click_button('Comment')
      end
    end
  end

  step 'I submit the diff comment' do
    page.within(diff_file_selector) do
      click_button("Comment")
    end
  end

  step 'I should not see the diff comment form' do
    page.within(diff_file_selector) do
      expect(page).not_to have_css("form.new_note")
    end
  end

  step 'The diff comment preview tab should say there is nothing to do' do
    page.within(diff_file_selector) do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_content('Nothing to preview.')
    end
  end

  step 'I should not see the diff comment text field' do
    page.within(diff_file_selector) do
      expect(find('.js-note-text')).not_to be_visible
    end
  end

  step 'I should only see one diff form' do
    page.within(diff_file_selector) do
      expect(page).to have_css("form.new-note", count: 1)
    end
  end

  step 'I should see a diff comment form with ":-1: I don\'t like this"' do
    page.within(diff_file_selector) do
      expect(page).to have_field("note[note]", with: ":-1: I don\'t like this")
    end
  end

  step 'I should see a diff comment saying "Typo, please fix"' do
    page.within("#{diff_file_selector} .note") do
      expect(page).to have_content("Typo, please fix")
    end
  end

  step 'I should see a diff comment on the left side saying "Old comment"' do
    page.within("#{diff_file_selector} .notes_content.parallel.old") do
      expect(page).to have_content("Old comment")
    end
  end

  step 'I should see a diff comment on the right side saying "New comment"' do
    page.within("#{diff_file_selector} .notes_content.parallel.new") do
      expect(page).to have_content("New comment")
    end
  end

  step 'I should see a discussion reply button' do
    page.within(diff_file_selector) do
      expect(page).to have_button('Reply...')
    end
  end

  step 'I should see a temporary diff comment form' do
    page.within(diff_file_selector) do
      expect(page).to have_css(".js-temp-notes-holder form.new-note")
    end
  end

  step 'I should see an empty diff comment form' do
    page.within(diff_file_selector) do
      expect(page).to have_field("note[note]", with: "")
    end
  end

  step 'I should see the cancel comment button' do
    page.within("#{diff_file_selector} form") do
      expect(page).to have_css(".js-close-discussion-note-form", text: "Cancel")
    end
  end

  step 'I should see the diff comment preview' do
    page.within("#{diff_file_selector} form") do
      expect(page).to have_css('.js-md-preview', visible: true)
    end
  end

  step 'I should see the diff comment write tab' do
    page.within(diff_file_selector) do
      expect(page).to have_css('.js-md-write-button', visible: true)
    end
  end

  step 'The diff comment preview tab should display rendered Markdown' do
    page.within(diff_file_selector) do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_css('gl-emoji', visible: true)
    end
  end

  step 'I should see two separate previews' do
    page.within(diff_file_selector) do
      expect(page).to have_css('.js-md-preview', visible: true, count: 2)
      expect(page).to have_content('Should fix it')
      expect(page).to have_content('DRY this up')
    end
  end

  step 'I should see a diff comment with an emoji image' do
    page.within("#{diff_file_selector} .note") do
      expect(page).to have_xpath("//gl-emoji[@data-name='smile']")
    end
  end

  step 'I click side-by-side diff button' do
    find('#parallel-diff-btn').click
  end

  step 'I see side-by-side diff button' do
    expect(page).to have_content "Side-by-side"
  end

  def diff_file_selector
    '.diff-file:nth-of-type(1)'
  end

  def click_diff_line(code)
    find(".line_holder[id='#{code}'] button").click
  end

  def click_parallel_diff_line(code, line_type)
    find(".line_holder.parallel td[id='#{code}']").find(:xpath, 'preceding-sibling::*[1][self::td]').hover
    find(".line_holder.parallel button[data-line-code='#{code}']").click
  end
end
