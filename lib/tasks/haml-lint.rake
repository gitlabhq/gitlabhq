unless Rails.env.production?
  require 'haml_lint/rake_task'
  require 'haml_lint/inline_javascript'

  HamlLint::RakeTask.new
end
