unless Rails.env.production?
  desc "GitLab | Run ESLint"
  task eslint: ['yarn:check'] do
    sh "yarn run eslint" do |ok, res|
      abort('rake eslint failed') unless ok
    end
  end
end
