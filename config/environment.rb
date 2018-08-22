# Load the rails application

# Remove this condition when upgraded to rails 5.0.
if %w[0 false].include?(ENV["RAILS5"])
  require File.expand_path('application', __dir__)
else
  require_relative 'application'
end

# Initialize the rails application
Rails.application.initialize!
