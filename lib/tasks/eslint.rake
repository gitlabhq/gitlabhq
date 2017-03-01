unless Rails.env.production?
  desc "GitLab | Run ESLint"
  task eslint: ['yarn:check'] do
    unless system('yarn run eslint')
      abort('rake eslint failed')
    end
  end
end
