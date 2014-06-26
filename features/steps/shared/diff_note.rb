module SharedDiffNote
  include Spinach::DSL

  Given 'I cancel the diff comment' do
    within(diff_file_selector) do
      find(".js-close-discussion-note-form").click
    end
  end

  Given 'I delete a diff comment' do
    find('.note').hover
    find(".js-note-delete").click
  end

  Given 'I haven\'t written any diff comment text' do
    within(diff_file_selector) do
      fill_in "note[note]", with: ""
    end
  end

  Given 'I leave a diff comment like "Typo, please fix"' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]').click
    within("#{diff_file_selector} form[rel$='586fb7c4e1add2d4d24e27566ed7064680098646_29_14']") do
      fill_in "note[note]", with: "Typo, please fix"
      find(".js-comment-button").trigger("click")
      sleep 0.05
    end
  end

  Given 'I preview a diff comment text like "Should fix it :smile:"' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]').click
    within("#{diff_file_selector} form[rel$='586fb7c4e1add2d4d24e27566ed7064680098646_29_14']") do
      fill_in "note[note]", with: "Should fix it :smile:"
      find(".js-note-preview-button").trigger("click")
    end
  end

  Given 'I preview another diff comment text like "DRY this up"' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_57_41"]').click

    within("#{diff_file_selector} form[rel$='586fb7c4e1add2d4d24e27566ed7064680098646_57_41']") do
      fill_in "note[note]", with: "DRY this up"
      find(".js-note-preview-button").trigger("click")
    end
  end

  Given 'I open a diff comment form' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]').click
  end

  Given 'I open another diff comment form' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_57_41"]').click
  end

  Given 'I write a diff comment like ":-1: I don\'t like this"' do
    within(diff_file_selector) do
      fill_in "note[note]", with: ":-1: I don\'t like this"
    end
  end

  Given 'I submit the diff comment' do
    within(diff_file_selector) do
      click_button("Add Comment")
    end
  end

  Then 'I should not see the diff comment form' do
    within(diff_file_selector) do
      page.should_not have_css("form.new_note")
    end
  end

  Then 'I should not see the diff comment preview button' do
    within(diff_file_selector) do
      page.should have_css(".js-note-preview-button", visible: false)
    end
  end

  Then 'I should not see the diff comment text field' do
    within(diff_file_selector) do
      page.should have_css(".js-note-text", visible: false)
    end
  end

  Then 'I should only see one diff form' do
    within(diff_file_selector) do
      page.should have_css("form.new_note", count: 1)
    end
  end

  Then 'I should see a diff comment form with ":-1: I don\'t like this"' do
    within(diff_file_selector) do
      page.should have_field("note[note]", with: ":-1: I don\'t like this")
    end
  end

  Then 'I should see a diff comment saying "Typo, please fix"' do
    within("#{diff_file_selector} .note") do
      page.should have_content("Typo, please fix")
    end
  end

  Then 'I should see a discussion reply button' do
    within(diff_file_selector) do
      page.should have_link("Reply")
    end
  end

  Then 'I should see a temporary diff comment form' do
    within(diff_file_selector) do
      page.should have_css(".js-temp-notes-holder form.new_note")
    end
  end

  Then 'I should see add a diff comment button' do
    page.should have_css(".js-add-diff-note-button", visible: false)
  end

  Then 'I should see an empty diff comment form' do
    within(diff_file_selector) do
      page.should have_field("note[note]", with: "")
    end
  end

  Then 'I should see the cancel comment button' do
    within("#{diff_file_selector} form") do
      page.should have_css(".js-close-discussion-note-form", text: "Cancel")
    end
  end

  Then 'I should see the diff comment preview' do
    within("#{diff_file_selector} form") do
      page.should have_css(".js-note-preview", visible: false)
    end
  end

  Then 'I should see the diff comment edit button' do
    within(diff_file_selector) do
      page.should have_css(".js-note-write-button", visible: true)
    end
  end

  Then 'I should see the diff comment preview button' do
    within(diff_file_selector) do
      page.should have_css(".js-note-preview-button", visible: true)
    end
  end

  Then 'I should see two separate previews' do
    within(diff_file_selector) do
      page.should have_css(".js-note-preview", visible: true, count: 2)
      page.should have_content("Should fix it")
      page.should have_content("DRY this up")
    end
  end

  def diff_file_selector
    ".diff-file"
  end
end
