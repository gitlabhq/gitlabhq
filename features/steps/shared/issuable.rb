module SharedIssuable
  include Spinach::DSL

  def edit_issuable
    find(:css, '.issuable-edit').click
  end

  step 'I click link "Edit" for the merge request' do
    edit_issuable
  end

  step 'I click link "Edit" for the issue' do
    edit_issuable
  end
end
