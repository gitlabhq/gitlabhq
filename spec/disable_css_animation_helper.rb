Capybara.register_driver :poltergeist do |app|
  opts = {
    extensions: ["#{Rails.root}/spec/disable_css_animation.js"] # or wherever
  }

  Capybara::Poltergeist::Driver.new(app, opts)
end

Capybara.javascript_driver = :poltergeist
