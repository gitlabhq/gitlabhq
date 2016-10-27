unless Rails.env.production?
  namespace :lint do
    desc "GitLab | lint | Lint JavaScript files using ESLint"
    task :javascript do
      Rake::Task['eslint'].invoke
    end
  end
end

