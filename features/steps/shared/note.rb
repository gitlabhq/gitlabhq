module SharedNote
  include Spinach::DSL

  Given 'I leave a comment like "XML attached"' do
    fill_in "note_note", :with => "XML attached"
    click_button "Add Comment"
  end

  Then 'I should see comment "XML attached"' do
    page.should have_content "XML attached"
  end

  Given 'I write new comment "my special test message"' do
    fill_in "note_note", :with => "my special test message"
    click_button "Add Comment"
  end

  Then 'I should see project wall note "my special test message"' do
    page.should have_content "my special test message"
  end
end
