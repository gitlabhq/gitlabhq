class Spinach::Features::ProjectStar < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedUser

  step "The project has no stars" do
    expect(page).not_to have_content '.toggle-star'
  end

  step "The project has 0 stars" do
    has_n_stars(0)
  end

  step "The project has 1 star" do
    has_n_stars(1)
  end

  step "The project has 2 stars" do
    has_n_stars(2)
  end

  # Requires @javascript
  step "I click on the star toggle button" do
    find(".star-btn", visible: true).click
  end

  step 'I redirected to sign in page' do
    expect(current_path).to eq new_user_session_path
  end

  protected

  def has_n_stars(n)
    expect(page).to have_css(".star-count", text: n, visible: true)
  end
end
