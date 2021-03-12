# frozen_string_literal: true

unless Rails.env.production?
  desc "GitLab | Run ESLint"
  task eslint: ['yarn:check'] do
    unless system('yarn run lint:eslint:all')
      abort('rake eslint failed')
    end
  end
end
