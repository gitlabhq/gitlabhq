# frozen_string_literal: true

namespace :gitlab do
  namespace :ci_secure_files do
    desc 'GitLab | CI Secure Files | Check integrity of uploaded Secure Files'
    task check: :environment do
      Gitlab::Verify::RakeTask.run!(Gitlab::Verify::CiSecureFiles)
    end
  end
end
