# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Identifier
          attr_reader :external_id
          attr_reader :external_type
          attr_reader :fingerprint
          attr_reader :name
          attr_reader :url

          def initialize(external_id:, external_type:, name:, url: nil)
            @external_id = external_id
            @external_type = external_type
            @name = name
            @url = url

            @fingerprint = generate_fingerprint
          end

          def key
            fingerprint
          end

          def to_hash
            %i[
              external_id
              external_type
              fingerprint
              name
              url
            ].index_with do |key|
              public_send(key) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def ==(other)
            other.external_type == external_type &&
              other.external_id == external_id
          end

          def type_identifier?
            cwe? || wasc?
          end

          def cve?
            external_type.to_s.casecmp?('cve')
          end

          def cwe?
            external_type.to_s.casecmp?('cwe')
          end

          def wasc?
            external_type.to_s.casecmp?('wasc')
          end

          def vendor
            # https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/902c7dcb5f3a0e551223167931ebf39588a0193a/identifier.go#L46
            case external_type.downcase
            when 'cve'
              'NVD'
            when 'elsa'
              'Oracle'
            when 'ghsa'
              'GitHub'
            when 'hackerone'
              'HackerOne'
            when 'osvdb'
              'OSVDB'
            when 'rhsa'
              'RedHat'
            when 'usn'
              'Ubuntu'
            else
              'Unknown'
            end
          end

          private

          def generate_fingerprint
            Digest::SHA1.hexdigest("#{external_type}:#{external_id}")
          end
        end
      end
    end
  end
end
