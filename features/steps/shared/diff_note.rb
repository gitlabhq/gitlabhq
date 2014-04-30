module SharedDiffNote
  include Spinach::DSL

  Given 'I cancel the diff comment' do
    within('.diff-file') do
      find('.js-close-discussion-note-form').click
    end
  end

  Given 'I delete a diff comment' do
    find('.note').hover
    find('.js-note-delete').click
  end

  Given 'I haven\'t written any diff comment text' do
    within('.diff-file') do
      fill_in 'note[note]', with: ''
    end
  end

  Given 'I leave a diff comment like "Typo, please fix"' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]')
      .click
    within(".diff-file form[rel$='586fb7c4e1add2d4d24e2" \
           "7566ed7064680098646_29_14']") do
      fill_in 'note[note]', with: 'Typo, please fix'
      find('.js-comment-button').trigger('click')
      sleep 0.05
    end
  end

  Given 'I open a diff comment form' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]')
      .click
  end

  Given 'I open another diff comment form' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_57_41"]')
      .click
  end

  Given 'I write a diff comment like ":-1: I don\'t like this"' do
    within('.diff-file') do
      fill_in 'note[note]', with: ":-1: I don\'t like this"
    end
  end

  Given 'I submit the diff comment' do
    within('.diff-file') do
      click_button('Add Comment')
    end
  end

  Then 'I should not see the diff comment form' do
    within('.diff-file') do
      page.should_not have_css('form.new_note')
    end
  end

  Then 'I should not see the diff comment text field' do
    within('.diff-content') do
      page.should have_css('.js-gfm-input', visible: false)
    end
  end

  Then 'I should only see one diff form' do
    within('.diff-file') do
      page.should have_css('form.new_note', count: 1)
    end
  end

  Then 'I should see a diff comment form with ":-1: I don\'t like this"' do
    within('.diff-file') do
      page.should have_field('note[note]', with: ":-1: I don\'t like this")
    end
  end

  Then 'I should see a diff comment saying "Typo, please fix"' do
    within('.diff-file .note') do
      page.should have_content('Typo, please fix')
    end
  end

  Then 'I should see a discussion reply button' do
    within('.diff-file') do
      page.should have_link('Reply')
    end
  end

  Then 'I should see a temporary diff comment form' do
    within('.diff-file') do
      page.should have_css('.js-temp-notes-holder form.new_note')
    end
  end

  Then 'I should see add a diff comment button' do
    page.should have_css('.js-add-diff-note-button', visible: false)
  end

  Then 'I should see an empty diff comment form' do
    within('.diff-file') do
      page.should have_field('note[note]', with: '')
    end
  end

  Then 'I should see the cancel comment button' do
    within('.diff-file form') do
      page.should have_css('.js-close-discussion-note-form', text: 'Cancel')
    end
  end

  # Preview

  Given 'I preview a diff comment text like "Should fix it :smile:"' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]')
      .click
    preview_markdown_with(".diff-content form[rel$='586fb7c4e1add2d4d24e275" \
                          "66ed7064680098646_29_14']", 'Should fix it :smile:')
  end

  Given 'I preview another diff comment text like "DRY this up"' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_57_41"]')
      .click
    preview_markdown_with(".diff-content form[rel$='586fb7c4e1add2d4d24e2756" \
                          "6ed7064680098646_57_41']", 'DRY this up')
  end

  Then 'I should see two separate previews' do
    within('.diff-content') do
      page.should have_css('.js-gfm-preview', visible: true, count: 2)
      page.should have_content('Should fix it')
      page.should have_content('DRY this up')
    end
  end

  Then 'The diff comment preview button should be enabled' do
    markdown_preview_button_should_be_enabled('.diff-content', true)
  end

  Then 'The diff comment preview button should be disabled' do
    markdown_preview_button_should_be_enabled('.diff-content', false)
  end

  Then 'I should see the diff comment preview' do
    should_see_the_markdown_preview('.diff-content form', true)
  end

  Then 'I should see the diff comment edit button' do
    should_see_markdown_edit_button('.diff-content', true)
  end

  Given 'I preview a diff comment text with a header' do
    find('a[data-line-code="586fb7c4e1add2d4d24e27566ed7064680098646_29_14"]')
      .click
    preview_markdown_with_header(".diff-content form[rel$='586fb7c4e1add2d4d2" \
                                 "4e27566ed7064680098646_29_14']")
  end

  Then 'The diff comment preview header should have no id' do
    preview_header_should_not_have_id(".diff-content form[rel$='586fb7c4e1add" \
                                      "2d4d24e27566ed7064680098646_29_14']")
  end
end
