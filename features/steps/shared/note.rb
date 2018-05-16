module SharedNote
  include Spinach::DSL
  include WaitForRequests

  after do
    wait_for_requests if javascript_test?
  end

  step 'I haven\'t written any comment text' do
    page.within(".js-main-target-form") do
      fill_in "note[note]", with: ""
    end
  end

  step 'The comment preview tab should say there is nothing to do' do
    page.within(".js-main-target-form") do
      find('.js-md-preview-button').click
      expect(find('.js-md-preview')).to have_content('Nothing to preview.')
    end
  end

  step 'I should see no notes at all' do
    expect(page).not_to have_css('.note')
  end
end
