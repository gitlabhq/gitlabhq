module SharedDashboard
  include Spinach::DSL

  step 'I click "Authored by me" link' do
    within ".assignee-filter" do
      click_link "Any"
    end
    within ".author-filter" do
      click_link current_user.name
    end
  end

  step 'I click "All" link' do
    within ".author-filter" do
      click_link "Any"
    end
    within ".assignee-filter" do
      click_link "Any"
    end
  end
end
