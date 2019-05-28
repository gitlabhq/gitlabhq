unless Rails.env.production?
  require 'haml_lint/rake_task'
  require Rails.root.join('haml_lint/inline_javascript')

  # Workaround for warnings from parser/current
  # Keep it even if it no longer emits any warnings,
  # because we'll still see warnings in console/server anyway,
  # and we don't need to break static-analysis for this.
  task :haml_lint do
    require 'parser'
    def Parser.warn(*args)
      puts(*args) # static-analysis ignores stdout if status is 0
    end
  end

  HamlLint::RakeTask.new
end
