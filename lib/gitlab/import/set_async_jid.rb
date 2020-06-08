# frozen_string_literal: true

# The original import JID is the JID of the RepositoryImportWorker job,
# which will be removed once that job completes. Reusing that JID could
# result in Gitlab::Import::StuckProjectImportJobsWorker marking the job
# as stuck before we get to running Stage::ImportRepositoryWorker.
#
# We work around this by setting the JID to a custom generated one, then
# refreshing it in the various stages whenever necessary.
module Gitlab
  module Import
    module SetAsyncJid
      def self.set_jid(import_state)
        jid = generate_jid(import_state)

        Gitlab::SidekiqStatus.set(jid, Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)

        import_state.update_column(:jid, jid)
      end

      def self.generate_jid(import_state)
        importer_name = import_state.class.name.underscore.dasherize
        "async-import/#{importer_name}/#{import_state.project_id}"
      end
    end
  end
end
