# Steps that can be shared between similar views such as issues,
# merge requests and milestones.
module SharedIssue
  include Spinach::DSL

  step 'I click link "Edit"' do
    click_link 'Edit'
  end

  step 'The description preview button should be enabled' do
    markdown_preview_button_should_be_enabled('.description', true)
  end

  step 'The description preview button should be disabled' do
    markdown_preview_button_should_be_enabled('.description', false)
  end

  step 'I input a description with a header' do
    within('.description') do
      find('textarea').set('# Description header')
    end
  end

  step 'I click on the description preview button' do
    click_markdown_preview_button('.description')
  end

  step 'The description preview header should have an id' do
    header_should_have_correct_id_and_link(1, 'Description header',
                                           'description-header', '.description')
  end

  step 'Header "Description header" should have correct id and link' do
    header_should_have_correct_id_and_link(1, 'Description header',
                                           'description-header')
  end
end
