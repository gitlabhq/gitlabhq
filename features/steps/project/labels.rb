class Spinach::Features::Labels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown

  step 'And I visit project "Shop" labels page' do
    visit namespace_project_labels_path(project.namespace, project)
  end

  step 'I should see that I am subscribed' do
    expect(subscribe_button).to have_content 'Unsubscribe'
  end

  step 'I should see that I am unsubscribed' do
    expect(subscribe_button).to have_content 'Subscribe'
  end

  step 'I click button "Unsubscribe"' do
    subscribe_button.click
  end

  step 'I click button "Subscribe"' do
    subscribe_button.click
  end

  private

  def subscribe_button
    first('.subscribe-button span')
  end
end
