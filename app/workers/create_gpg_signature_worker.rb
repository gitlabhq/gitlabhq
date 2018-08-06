# frozen_string_literal: true

class CreateGpgSignatureWorker
  include ApplicationWorker

  def perform(commit_shas, project_id)
    # Older versions of GitPushService may push a single commit ID on the stack.
    # We need this to be backwards compatible.
    commit_shas = Array(commit_shas)

    return if commit_shas.empty?

    project = Project.find_by(id: project_id)
    return unless project

    commits = project.commits_by(oids: commit_shas)

    return if commits.empty?

    # This calculates and caches the signature in the database
    commits.each do |commit|
      begin
        Gitlab::Gpg::Commit.new(commit).signature
      rescue => e
        Rails.logger.error("Failed to create signature for commit #{commit.id}. Error: #{e.message}")
      end
    end
  end
end
