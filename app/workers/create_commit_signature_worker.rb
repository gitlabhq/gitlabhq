# frozen_string_literal: true

class CreateCommitSignatureWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management
  weight 2
  idempotent!
  loggable_arguments 0

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(commit_shas, project_id)
    # Older versions of Git::BranchPushService may push a single commit ID on
    # the stack. We need this to be backwards compatible.
    commit_shas = Array(commit_shas)

    return if commit_shas.empty?

    project = Project.find_by(id: project_id)
    return unless project

    commits = project.commits_by(oids: commit_shas)

    return if commits.empty?

    # Instantiate commits first to lazily load the signatures
    commits.map! do |commit|
      case commit.signature_type
      when :PGP
        Gitlab::Gpg::Commit.new(commit)
      when :X509
        Gitlab::X509::Commit.new(commit)
      end
    end

    # This calculates and caches the signature in the database
    commits.each do |commit|
      commit&.signature
    rescue StandardError => e
      Gitlab::AppLogger.error("Failed to create signature for commit #{commit.id}. Error: #{e.message}")
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
