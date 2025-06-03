# frozen_string_literal: true

desc "GitLab | X509 | Update signatures when certificate store has changed"
namespace :gitlab do
  namespace :x509 do
    task update_signatures: :environment do
      require 'logger'

      update_certificates
    end

    def update_certificates
      logger = Logger.new($stdout)

      unless CommitSignatures::X509CommitSignature.exists?
        logger.info("Unable to find any x509 commit signatures. Exiting.")
        return
      end

      logger.info("Start to update x509 commit signatures")

      CommitSignatures::X509CommitSignature.find_each do |sig|
        logger.debug do
          "Start to update x509 commit signature #{sig.id} for commit SHA #{sig.commit_sha}, " \
            "project id #{sig.project_id} and x509 certificate id #{sig.x509_certificate_id}."
        end

        sig.x509_commit&.update_signature!(sig)
      end

      logger.info("End update x509 commit signatures")
    end
  end
end
