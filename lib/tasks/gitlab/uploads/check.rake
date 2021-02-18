# frozen_string_literal: true

namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Check integrity of uploaded files'
    task check: :environment do
      Gitlab::Verify::RakeTask.run!(Gitlab::Verify::Uploads)
    end
  end
end
