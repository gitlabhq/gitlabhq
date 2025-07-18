# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Finding
          include ::VulnerabilityFindingHelpers
          include Gitlab::Utils::StrongMemoize

          attr_reader :confidence
          attr_reader :identifiers
          attr_reader :flags
          attr_reader :links
          attr_reader :location
          attr_reader :evidence
          attr_reader :metadata_version
          attr_reader :name
          attr_reader :old_location
          attr_reader :report_type
          attr_reader :scanner
          attr_reader :scan
          attr_reader :severity
          attr_accessor :uuid
          attr_accessor :overridden_uuid
          attr_reader :remediations
          attr_reader :details
          attr_reader :signatures
          attr_reader :project_id
          attr_reader :original_data
          attr_reader :found_by_pipeline
          attr_reader :cvss

          delegate :file_path, :start_line, :end_line, to: :location

          def initialize(identifiers:, location:, evidence:, metadata_version:, name:, original_data:, report_type:, scanner:, scan:, uuid:, flags: [], links: [], remediations: [], confidence: nil, severity: nil, details: {}, signatures: [], project_id: nil, vulnerability_finding_signatures_enabled: false, found_by_pipeline: nil, cvss: []) # rubocop:disable Metrics/ParameterLists -- TODO: Reduce number of parameters in this function
            @confidence = confidence
            @identifiers = identifiers
            @flags = flags
            @links = links
            @location = location
            @evidence = evidence
            @metadata_version = metadata_version
            @name = name
            @original_data = original_data
            @report_type = report_type
            @scanner = scanner
            @scan = scan
            @severity = severity
            @uuid = uuid
            @remediations = remediations
            @details = details
            @signatures = signatures
            @project_id = project_id
            @vulnerability_finding_signatures_enabled = vulnerability_finding_signatures_enabled
            @found_by_pipeline = found_by_pipeline
            @cvss = cvss
          end

          def to_hash
            %i[
              confidence
              identifiers
              flags
              links
              location
              evidence
              metadata_version
              name
              raw_metadata
              report_type
              scanner
              scan
              severity
              uuid
              details
              signatures
              description
              solution
            ].index_with do |key|
              public_send(key) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def primary_identifier
            identifiers.first
          end

          def update_location(new_location)
            @old_location = location
            @location = new_location
          end

          def unsafe?(severity_levels, report_types)
            severity.to_s.in?(severity_levels) && (report_types.blank? || report_type.to_s.in?(report_types))
          end

          def eql?(other)
            return false unless report_type == other.report_type && primary_identifier_fingerprint == other.primary_identifier_fingerprint

            if @vulnerability_finding_signatures_enabled
              matches_signatures(other.signatures, other.uuid)
            else
              location.fingerprint == other.location.fingerprint
            end
          end

          def hash
            if @vulnerability_finding_signatures_enabled && !signatures.empty?
              highest_signature = signatures.max_by(&:priority)
              report_type.hash ^ highest_signature.signature_hex.hash ^ primary_identifier_fingerprint.hash
            else
              report_type.hash ^ location.fingerprint.hash ^ primary_identifier_fingerprint.hash
            end
          end

          def valid?
            scanner.present? && primary_identifier.present? && location.present? && uuid.present?
          end

          def keys
            @keys ||= identifiers.reject(&:type_identifier?).flat_map do |identifier|
              location_fingerprints.map do |location_fingerprint|
                FindingKey.new(location_fingerprint: location_fingerprint, identifier_fingerprint: identifier.fingerprint)
              end
            end.push(uuid)
          end

          def primary_identifier_fingerprint
            primary_identifier&.fingerprint
          end

          def <=>(other)
            if severity == other.severity
              uuid <=> other.uuid
            else
              ::Enums::Vulnerability.severity_levels[other.severity] <=>
                ::Enums::Vulnerability.severity_levels[severity]
            end
          end

          def scanner_order_to(other)
            return 1 unless scanner
            return -1 unless other&.scanner

            scanner <=> other.scanner
          end

          def has_signatures?
            signatures.present?
          end

          def false_positive?
            flags.any?(&:false_positive?)
          end

          def remediation_byte_offsets
            remediations.map(&:byte_offsets).compact
          end

          def raw_metadata
            @raw_metadata ||= original_data.to_json
          end

          def description
            original_data['description']
          end

          def solution
            original_data['solution']
          end

          def location_data
            original_data['location']
          end

          def assets
            original_data['assets'] || []
          end

          def raw_source_code_extract
            original_data['raw_source_code_extract']
          end

          # Returns either the max priority signature hex
          # or the location fingerprint
          def location_fingerprint
            location_fingerprints.first
          end

          def owasp_top_10
            extract_owasp_top_10
          end
          strong_memoize_attr :owasp_top_10

          def has_vulnerability_resolution?
            extract_vulnerability_resolution
          end
          strong_memoize_attr :has_vulnerability_resolution?

          private

          def location_fingerprints
            @location_fingerprints ||= signature_hexes << location&.fingerprint
          end

          # Returns the signature hexes in reverse priority order
          def signature_hexes
            return [] unless @vulnerability_finding_signatures_enabled && signatures.present?

            signatures.sort_by { |sig| -sig.priority }.map(&:signature_hex)
          end

          def extract_owasp_top_10
            owasp_identifier = identifiers.find { |id| id.external_type.casecmp?('owasp') }
            return ::Vulnerabilities::Read::OWASP_TOP_10_DEFAULT unless owasp_identifier

            map_owasp_external_id(owasp_identifier.external_id)
          end

          def map_owasp_external_id(external_id)
            default_value = ::Vulnerabilities::Read::OWASP_TOP_10_DEFAULT

            return default_value unless valid_owasp_external_id?(external_id)

            ::Enums::Vulnerability.owasp_top_10.keys.find { |key| key.include?(external_id) } ||
              default_value
          end

          def valid_owasp_external_id?(external_id)
            arr = external_id.split(':')

            priority_label = arr.first
            year = arr.second ? arr.second[0..3] : nil

            return false if year.nil? || ::Enums::Vulnerability.owasp_years.exclude?(year)

            Enums::Vulnerability.owasp_categories.include?(priority_label)
          end

          def extract_vulnerability_resolution
            report_type_str = report_type.to_s
            cwe_identifier = identifiers.find { |id| id.external_type == 'cwe' }
            return false unless cwe_identifier

            cwe_value = cwe_identifier.name
            return false unless cwe_value

            ::Vulnerabilities::Finding::AI_ALLOWED_REPORT_TYPES.include?(report_type_str) &&
              ::Vulnerabilities::Finding::HIGH_CONFIDENCE_AI_RESOLUTION_CWES.include?(cwe_value&.upcase)
          end
        end
      end
    end
  end
end
