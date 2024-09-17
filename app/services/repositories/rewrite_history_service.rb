# frozen_string_literal: true

# Rewrites repository history via RewriteHistory RPC:
# - deletes requested blobs in a repository
# - redacts text strings found in a repository
module Repositories
  class RewriteHistoryService < ::BaseService
    def execute(blob_oids: [], redactions: [])
      return ServiceResponse.error(message: _('Access Denied')) unless allowed?
      return ServiceResponse.error(message: _('not enough arguments')) if blob_oids.blank? && redactions.blank?

      result = mark_repository_read_only
      return result if result.error?

      rewrite_history(blob_oids: blob_oids, redactions: redactions)
    end

    private

    def allowed?
      Ability.allowed?(current_user, :owner_access, project)
    end

    def mark_repository_read_only
      project.set_repository_read_only!
      ServiceResponse.success
    rescue Project::RepositoryReadOnlyError => e
      ServiceResponse.error(message: e.message)
    end

    def rewrite_history(blob_oids:, redactions:)
      client = Gitlab::GitalyClient::CleanupService.new(project.repository)
      client.rewrite_history(blobs: blob_oids, redactions: redactions)

      audit_removals(blob_oids) if blob_oids.present?
      audit_replacements if redactions.present?

      ServiceResponse.success
    rescue ArgumentError => e
      ServiceResponse.error(message: e.message)
    ensure
      project.set_repository_writable!
    end

    def audit_removals(blob_oids)
      context = {
        name: 'project_blobs_removal',
        author: current_user,
        scope: project,
        target: project,
        message: 'Project blobs removed',
        additional_details: { blob_oids: blob_oids }
      }

      ::Gitlab::Audit::Auditor.audit(context)
    end

    def audit_replacements
      context = {
        name: 'project_text_replacement',
        author: current_user,
        scope: project,
        target: project,
        message: 'Project text replaced'
      }

      ::Gitlab::Audit::Auditor.audit(context)
    end
  end
end
