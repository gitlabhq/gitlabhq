unless Rails.env.production?
  require 'scss_lint/rake_task'

  SCSSLint::RakeTask.new do |t|
    t.config = '.scss-lint.yml'
    # See https://github.com/brigade/scss-lint/issues/726
    # Hack, otherwise linter won't respect scss_files option in config file.
    t.files = []
  end
end
