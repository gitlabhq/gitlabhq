# frozen_string_literal: true

namespace :gitlab do
  task list_repos: :environment do
    warn "The Rake task gitlab:list_repos is deprecated in 16.7 and will be removed in 17.0: " \
         "https://gitlab.com/gitlab-org/gitlab/-/issues/384361"

    scope = Project
    if ENV['SINCE']
      date = Time.parse(ENV['SINCE'])
      warn "Listing repositories with activity or changes since #{date}"
      project_ids = Project.where('last_activity_at > ? OR updated_at > ?', date, date).pluck(:id).sort
      namespace_ids = Namespace.where(['updated_at > ?', date]).pluck(:id).sort
      scope = scope.where('id IN (?) OR namespace_id in (?)', project_ids, namespace_ids)
    end

    scope.find_each do |project|
      puts project.repository.path_to_repo
      puts project.wiki.repository.path_to_repo
    end
  end
end
