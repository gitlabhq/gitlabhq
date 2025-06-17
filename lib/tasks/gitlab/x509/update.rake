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
      rescue GRPC::DeadlineExceeded => e
        logger.error do
          "GRPC deadline exceeded while updating signature #{sig.id} for commit #{sig.commit_sha}: #{e.message}"
        end

        error_counter ||= 0
        error_counter += 1
        raise e unless error_counter < grpc_deadline_exceeded_retry_limit

        logger.debug("Retrying to update signature #{sig.id} for commit #{sig.commit_sha}")
        sleep(error_counter)
        retry
      else
        error_counter = 0
      end

      logger.info("End update x509 commit signatures")
    end

    def grpc_deadline_exceeded_retry_limit
      (ENV['GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT'] || 5).to_i
    end
  end
end
