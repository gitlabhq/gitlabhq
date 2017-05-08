unless Rails.env.production?
  namespace :lint do
    desc "GitLab | lint | Lint JavaScript files using ESLint"
    task :javascript do
      Rake::Task['eslint'].invoke
    end

    desc 'GitLab | lint | Check JavaScript bundle files for suboptimal bundling'
    task :js_bundles do
      Rake::Task['js_bundles_check'].invoke
    end
  end
end
