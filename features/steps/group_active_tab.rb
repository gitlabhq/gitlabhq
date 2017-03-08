class Spinach::Features::GroupActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedUser
  include SharedGroup
  include SharedPaths
  include SharedActiveTab

  step 'the active sub nav should be Audit Events' do
    ensure_active_sub_nav('Audit Events')
  end

  step 'the active main tab should be Settings' do
    page.within '.nav-sidebar' do
      expect(page).to have_content('Go to group')
    end
  end

  step 'the active sub nav should be Webhooks' do
    ensure_active_sub_nav('Webhooks')
  end

  step 'I go to "Audit Events"' do
    click_link 'Audit Events'
  end

  step 'I go to "Webhooks"' do
    click_link 'Webhooks'
  end
end
