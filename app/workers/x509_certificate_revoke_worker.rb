# frozen_string_literal: true

class X509CertificateRevokeWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management

  idempotent!

  def perform(certificate_id)
    return unless certificate_id

    X509Certificate.find_by_id(certificate_id).try do |certificate|
      X509CertificateRevokeService.new.execute(certificate)
    end
  end
end
