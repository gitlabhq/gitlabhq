# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Common
          SecurityReportParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def self.parse!(json_data, report, vulnerability_finding_signatures_enabled = false, validate: false)
            new(json_data, report, vulnerability_finding_signatures_enabled, validate: validate).parse!
          end

          def initialize(json_data, report, vulnerability_finding_signatures_enabled = false, validate: false)
            @json_data = json_data
            @report = report
            @validate = validate
            @vulnerability_finding_signatures_enabled = vulnerability_finding_signatures_enabled
          end

          def parse!
            return report_data unless valid?

            raise SecurityReportParserError, "Invalid report format" unless report_data.is_a?(Hash)

            create_scanner
            create_scan
            create_analyzer
            set_report_version

            create_findings

            report_data
          rescue JSON::ParserError
            raise SecurityReportParserError, 'JSON parsing failed'
          rescue StandardError => e
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
            raise SecurityReportParserError, "#{report.type} security report parsing failed"
          end

          private

          attr_reader :json_data, :report, :validate

          def valid?
            return true if !validate || schema_validator.valid?

            schema_validator.errors.each { |error| report.add_error('Schema', error) }

            false
          end

          def schema_validator
            @schema_validator ||= ::Gitlab::Ci::Parsers::Security::Validators::SchemaValidator.new(report.type, report_data)
          end

          def report_data
            @report_data ||= Gitlab::Json.parse!(json_data)
          end

          def report_version
            @report_version ||= report_data['version']
          end

          def top_level_scanner
            @top_level_scanner ||= report_data.dig('scan', 'scanner')
          end

          def scan_data
            @scan_data ||= report_data.dig('scan')
          end

          def analyzer_data
            @analyzer_data ||= report_data.dig('scan', 'analyzer')
          end

          def tracking_data(data)
            data['tracking']
          end

          def create_findings
            if report_data["vulnerabilities"]
              report_data["vulnerabilities"].each { |finding| create_finding(finding) }
            end
          end

          def create_finding(data, remediations = [])
            identifiers = create_identifiers(data['identifiers'])
            links = create_links(data['links'])
            location = create_location(data['location'] || {})
            signatures = create_signatures(tracking_data(data))

            if @vulnerability_finding_signatures_enabled && !signatures.empty?
              # NOT the signature_sha - the compare key is hashed
              # to create the project_fingerprint
              highest_priority_signature = signatures.max_by(&:priority)
              uuid = calculate_uuid_v5(identifiers.first, highest_priority_signature.signature_hex)
            else
              uuid = calculate_uuid_v5(identifiers.first, location&.fingerprint)
            end

            report.add_finding(
              ::Gitlab::Ci::Reports::Security::Finding.new(
                uuid: uuid,
                report_type: report.type,
                name: finding_name(data, identifiers, location),
                compare_key: data['cve'] || '',
                location: location,
                severity: parse_severity_level(data['severity']),
                confidence: parse_confidence_level(data['confidence']),
                scanner: create_scanner(data['scanner']),
                scan: report&.scan,
                identifiers: identifiers,
                links: links,
                remediations: remediations,
                raw_metadata: data.to_json,
                metadata_version: report_version,
                details: data['details'] || {},
                signatures: signatures,
                project_id: report.project_id,
                vulnerability_finding_signatures_enabled: @vulnerability_finding_signatures_enabled))
          end

          def create_signatures(tracking)
            tracking ||= { 'items' => [] }

            signature_algorithms = Hash.new { |hash, key| hash[key] = [] }

            tracking['items'].each do |item|
              next unless item.key?('signatures')

              item['signatures'].each do |signature|
                alg = signature['algorithm']
                signature_algorithms[alg] << signature['value']
              end
            end

            signature_algorithms.map do |algorithm, values|
              value = values.join('|')
              signature = ::Gitlab::Ci::Reports::Security::FindingSignature.new(
                algorithm_type: algorithm,
                signature_value: value
              )

              if signature.valid?
                signature
              else
                e = SecurityReportParserError.new("Vulnerability tracking signature is not valid: #{signature}")
                Gitlab::ErrorTracking.track_exception(e)
                nil
              end
            end.compact
          end

          def create_scan
            return unless scan_data.is_a?(Hash)

            report.scan = ::Gitlab::Ci::Reports::Security::Scan.new(scan_data)
          end

          def set_report_version
            report.version = report_version
          end

          def create_analyzer
            return unless analyzer_data.is_a?(Hash)

            params = {
              id: analyzer_data.dig('id'),
              name: analyzer_data.dig('name'),
              version: analyzer_data.dig('version'),
              vendor: analyzer_data.dig('vendor', 'name')
            }

            return unless params.values.all?

            report.analyzer = ::Gitlab::Ci::Reports::Security::Analyzer.new(**params)
          end

          def create_scanner(scanner_data = top_level_scanner)
            return unless scanner_data.is_a?(Hash)

            report.add_scanner(
              ::Gitlab::Ci::Reports::Security::Scanner.new(
                external_id: scanner_data['id'],
                name: scanner_data['name'],
                vendor: scanner_data.dig('vendor', 'name'),
                version: scanner_data.dig('version')))
          end

          def create_identifiers(identifiers)
            return [] unless identifiers.is_a?(Array)

            identifiers.map { |identifier| create_identifier(identifier) }.compact
          end

          def create_identifier(identifier)
            return unless identifier.is_a?(Hash)

            report.add_identifier(
              ::Gitlab::Ci::Reports::Security::Identifier.new(
                external_type: identifier['type'],
                external_id: identifier['value'],
                name: identifier['name'],
                url: identifier['url']))
          end

          def create_links(links)
            return [] unless links.is_a?(Array)

            links.map { |link| create_link(link) }.compact
          end

          def create_link(link)
            return unless link.is_a?(Hash)

            ::Gitlab::Ci::Reports::Security::Link.new(name: link['name'], url: link['url'])
          end

          def parse_severity_level(input)
            input&.downcase.then { |value| ::Enums::Vulnerability.severity_levels.key?(value) ? value : 'unknown' }
          end

          def parse_confidence_level(input)
            input&.downcase.then { |value| ::Enums::Vulnerability.confidence_levels.key?(value) ? value : 'unknown' }
          end

          def create_location(location_data)
            raise NotImplementedError
          end

          def finding_name(data, identifiers, location)
            return data['message'] if data['message'].present?
            return data['name'] if data['name'].present?

            identifier = identifiers.find(&:cve?) || identifiers.find(&:cwe?) || identifiers.first
            "#{identifier.name} in #{location&.fingerprint_path}"
          end

          def calculate_uuid_v5(primary_identifier, location_fingerprint)
            uuid_v5_name_components = {
              report_type: report.type,
              primary_identifier_fingerprint: primary_identifier&.fingerprint,
              location_fingerprint: location_fingerprint,
              project_id: report.project_id
            }

            if uuid_v5_name_components.values.any?(&:nil?)
              Gitlab::AppLogger.warn(message: "One or more UUID name components are nil", components: uuid_v5_name_components)
              return
            end

            ::Security::VulnerabilityUUID.generate(
              report_type: uuid_v5_name_components[:report_type],
              primary_identifier_fingerprint: uuid_v5_name_components[:primary_identifier_fingerprint],
              location_fingerprint: uuid_v5_name_components[:location_fingerprint],
              project_id: uuid_v5_name_components[:project_id]
            )
          end
        end
      end
    end
  end
end

Gitlab::Ci::Parsers::Security::Common.prepend_mod_with("Gitlab::Ci::Parsers::Security::Common")
