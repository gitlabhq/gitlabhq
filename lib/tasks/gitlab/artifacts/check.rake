# frozen_string_literal: true

namespace :gitlab do
  namespace :artifacts do
    desc 'GitLab | Artifacts | Check integrity of uploaded job artifacts'
    task check: :environment do
      Gitlab::Verify::RakeTask.run!(Gitlab::Verify::JobArtifacts)
    end
  end
end
