# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :permissions do
    desc 'Validate GitLab permission definitions'
    task validate: :environment do
      require_relative './validate_task'
      require_relative './assignable/validate_task'

      Tasks::Gitlab::Permissions::ValidateTask.new.run
      Tasks::Gitlab::Permissions::Assignable::ValidateTask.new.run
    end
  end
end
