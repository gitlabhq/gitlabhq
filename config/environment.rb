# Load the rails application

# Remove this condition when upgraded to rails 5.0.
if %w[1 true].include?(ENV["RAILS5"])
  require_relative 'application'
else
  require File.expand_path('../application', __FILE__)
end

# Initialize the rails application
Rails.application.initialize!
