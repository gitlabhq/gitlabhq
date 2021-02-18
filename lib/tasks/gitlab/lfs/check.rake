# frozen_string_literal: true

namespace :gitlab do
  namespace :lfs do
    desc 'GitLab | LFS | Check integrity of uploaded LFS objects'
    task check: :environment do
      Gitlab::Verify::RakeTask.run!(Gitlab::Verify::LfsObjects)
    end
  end
end
