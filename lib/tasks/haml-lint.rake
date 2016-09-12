unless Rails.env.production?
  require 'haml_lint/rake_task'

  HamlLint::RakeTask.new do |t|
    t.config = '.haml-lint.yml'
    t.files = ['app/views']
  end
end
