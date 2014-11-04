module SharedProjectSource
  include Spinach::DSL
  include RepoHelpers

  include ActionView::Helpers::JavaScriptHelper

  step 'I fill the new file name' do
    fill_in :file_name, with: new_file_name
  end

  step 'I click on "new file" link in repo' do
    click_link 'new-file-link'
  end

  step 'I edit code' do
    set_new_editor_content
  end

  step 'I should see the new edited content' do
    expect_editor_content(new_content)
  end

  step 'I fill the commit message' do
    fill_in :commit_message, with: 'Not yet a commit message.'
  end

  step 'I click on "Commit Changes"' do
    click_button 'Commit Changes'
  end

  step 'I should see its new content' do
    page.should have_content(new_content)
  end

  private

  def set_new_editor_content
    execute_script("editor.setValue('#{escape_javascript(new_content)}')")
  end

  def expect_editor_content(content)
    expect(evaluate_script('editor.getValue()')).to eq(content)
  end
end
