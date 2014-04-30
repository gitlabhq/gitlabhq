module SharedNote
  include Spinach::DSL

  Given 'I delete a comment' do
    find('.note').hover
    find('.js-note-delete').click
  end

  Given 'I haven\'t written any comment text' do
    within('.js-main-target-form') do
      fill_in 'note[note]', with: ''
    end
  end

  Given 'I leave a comment like "XML attached"' do
    within('.js-main-target-form') do
      fill_in 'note[note]', with: 'XML attached'
      click_button 'Add Comment'
      sleep 0.05
    end
  end

  Given 'I submit the comment' do
    within('.js-main-target-form') do
      click_button 'Add Comment'
    end
  end

  Given 'I write a comment like "Nice"' do
    within('.js-main-target-form') do
      fill_in 'note[note]', with: 'Nice'
    end
  end

  Then 'I should not see a comment saying "XML attached"' do
    page.should_not have_css('.note')
  end

  Then 'I should not see the cancel comment button' do
    within('.js-main-target-form') do
      should_not have_link('Cancel')
    end
  end

  Then 'I should see a comment saying "XML attached"' do
    within('.note') do
      page.should have_content('XML attached')
    end
  end

  Then 'I should see an empty comment text field' do
    within('.js-main-target-form') do
      page.should have_field('note[note]', with: '', visible: true)
    end
  end

  Then 'I should see comment "XML attached"' do
    within('.note') do
      page.should have_content('XML attached')
    end
  end

  # Markdown

  step 'I leave a comment with a header containing "Comment with a header"' do
    within('.js-main-target-form') do
      fill_in 'note[note]', with: '# Comment with a header'
      click_button 'Add Comment'
      sleep 0.05
    end
  end

  step 'The comment with the header should not have an ID' do
    within('.note-text') do
      page.should     have_content('Comment with a header')
      page.should_not have_css('#comment-with-a-header')
    end
  end

  # Preview

  step 'The markdown preview button should be enabled' do
    markdown_preview_button_should_be_enabled('.js-main-target-form', true)
  end

  step 'The markdown preview button should be disabled' do
    markdown_preview_button_should_be_enabled('.js-main-target-form', false)
  end

  step 'I should see the markdown edit button' do
    should_see_markdown_edit_button('.js-main-target-form', true)
  end

  step 'I click the markdown edit button' do
    click_markdown_edit_button('.js-main-target-form')
  end

  step 'I should see the markdown preview' do
    should_see_the_markdown_preview('.js-main-target-form', true)
  end

  step 'I should not see the markdown preview' do
    should_see_the_markdown_preview('.js-main-target-form', false)
  end

  step 'I should see the markdown input field' do
    should_see_the_markdown_input('.js-main-target-form', true)
  end

  step 'I should not see the markdown input field' do
    should_see_the_markdown_input('.js-main-target-form', false)
  end

  step 'I preview a markdown input with a header' do
    preview_markdown_with_header('.js-main-target-form')
  end

  step 'The input should be the header input' do
    input_should_be_header_input('.js-main-target-form')
  end

  step 'The preview header should not have an id' do
    preview_header_should_not_have_id('.js-main-target-form')
  end
end
