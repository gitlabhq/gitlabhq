# frozen_string_literal: true

module Gitlab
  module Ci
    module SecureFiles
      class X509Name
        def self.parse(x509_name)
          x509_name.to_utf8.split(',').to_h { |a| a.split('=') }
        rescue StandardError
          {}
        end
      end
    end
  end
end
