unless Rails.env.production?
  require 'haml_lint/rake_task'
  require 'haml_lint/inline_javascript'

  # Workaround for warnings from parser/current
  # TODO: Remove this after we update parser gem
  task :haml_lint do
    require 'parser'
    def Parser.warn(*args)
      puts(*args) # static-analysis ignores stdout if status is 0
    end
  end

  HamlLint::RakeTask.new
end
