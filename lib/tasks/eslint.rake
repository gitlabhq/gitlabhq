unless Rails.env.production?
  desc "GitLab | Run ESLint"
  task :eslint do
    system("yarn", "run", "eslint")
  end
end

