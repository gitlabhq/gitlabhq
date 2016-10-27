unless Rails.env.production?
  desc "GitLab | Run ESLint"
  task :eslint do
    system("npm", "run", "eslint")
  end
end

