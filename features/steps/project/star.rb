class Spinach::Features::ProjectStar < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedUser

  step "The project has no stars" do
    page.should_not have_content '.star-buttons'
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
    page.find(".star .toggle", visible: true).click
  end

  protected

  def has_n_stars(n)
    expect(page).to have_css(".star .count", text: /^#{n}$/, visible: true)
  end
end
