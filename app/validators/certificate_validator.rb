# UrlValidator
#
# Custom validator for private keys.
#
#   class Project < ActiveRecord::Base
#     validates :certificate_key, certificate_key: true
#   end
#
class CertificateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    certificate = parse_certificate(value)
    unless certificate
      record.errors.add(attribute, "must be a valid PEM certificate")
    end

    if options[:intermediates]
      unless certificate
        record.errors.add(attribute, "certificate verification failed: missing intermediate certificates")
      end
    end
  end

  private

  def parse_certificate(value)
    OpenSSL::X509::Certificate.new(value)
  rescue OpenSSL::X509::CertificateError
    nil
  end
end
