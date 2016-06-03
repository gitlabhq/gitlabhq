unless Rails.env.production?
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end
