module SharedMarkdown
  include Spinach::DSL

  step 'I should not see the Markdown preview' do
    expect(find('.gfm-form .js-md-preview')).not_to be_visible
  end

  step 'I haven\'t written any description text' do
    find('.gfm-form').fill_in 'Description', with: ''
  end
end
