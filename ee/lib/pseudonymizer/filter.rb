require 'openssl'
require 'digest'

module Pseudonymizer
  class Filter
    def initialize(table, whitelisted_fields, pseudonymized_fields)
      @table = table
      @pseudo_fields = pseudo_fields(whitelisted_fields, pseudonymized_fields)
    end

    def anonymize(results)
      key = Rails.application.secrets[:secret_key_base]
      digest = OpenSSL::Digest.new('sha256')

      Enumerator.new do |yielder|
        results.each do |result|
          @pseudo_fields.each do |field|
            next if result[field].nil?

            result[field] = OpenSSL::HMAC.hexdigest(digest, key, String(result[field]))
          end
          yielder << result
        end
      end
    end

    private

    def pseudo_fields(whitelisted, pseudonymized)
      pseudo_extra_fields = pseudonymized - whitelisted
      pseudo_extra_fields.each do |field|
        Rails.logger.warn("#{self.class.name} extraneous pseudo: #{@table}.#{field} is not whitelisted and will be ignored.")
      end

      pseudonymized & whitelisted
    end
  end
end
