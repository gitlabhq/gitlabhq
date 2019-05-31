# frozen_string_literal: true

# The original import JID is the JID of the RepositoryImportWorker job,
# which will be removed once that job completes. Reusing that JID could
# result in StuckImportJobsWorker marking the job as stuck before we get
# to running Stage::ImportRepositoryWorker.
#
# We work around this by setting the JID to a custom generated one, then
# refreshing it in the various stages whenever necessary.
module Gitlab
  module Import
    module SetAsyncJid
      def self.set_jid(project)
        jid = generate_jid(project)

        Gitlab::SidekiqStatus
          .set(jid, StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)

        project.import_state.update_column(:jid, jid)
      end

      def self.generate_jid(project)
        "async-import/#{project.id}"
      end
    end
  end
end
