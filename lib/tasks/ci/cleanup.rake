# frozen_string_literal: true

namespace :ci do
  namespace :cleanup do
    desc "GitLab | CI | Clean running builds"
    task builds: :environment do
      Ci::Build.running.update_all(status: 'canceled')
    end
  end
end
