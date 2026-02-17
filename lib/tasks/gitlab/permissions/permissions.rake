# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  namespace :permissions do
    desc 'Validate GitLab permission definitions'
    task validate: :environment do
      require_relative './validate_task'
      require_relative './assignable/validate_task'
      require_relative './routes/validate_task'

      Tasks::Gitlab::Permissions::ValidateTask.new.run
      Tasks::Gitlab::Permissions::Assignable::ValidateTask.new.run
      Tasks::Gitlab::Permissions::Routes::ValidateTask.new.run
      Tasks::Gitlab::Permissions::Routes::DocsTask.new.check_docs
    end

    namespace :routes do
      desc 'Compile documentation for endpoints with granular personal access token support'
      task compile_docs: :environment do
        require_relative './routes/docs_task'

        Tasks::Gitlab::Permissions::Routes::DocsTask.new.compile_docs
      end
    end
  end
end
