# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Common
          SecurityReportParserError = Class.new(Gitlab::Ci::Parsers::ParserError)

          def self.parse!(json_data, report, signatures_enabled: false, validate: false)
            new(json_data, report, signatures_enabled: signatures_enabled, validate: validate).parse!
          end

          def initialize(json_data, report, signatures_enabled: false, validate: false)
            @json_data = json_data
            @report = report
            @project = report.project
            @validate = validate
            @signatures_enabled = signatures_enabled
          end

          def parse!
            sanitize_json_data
            set_report_version

            return report_data unless valid?

            raise SecurityReportParserError, "Invalid report format" unless report_data.is_a?(Hash)

            create_scanner(top_level_scanner_data)
            create_scan
            create_analyzer

            create_findings

            report_data
          rescue JSON::ParserError
            raise SecurityReportParserError, 'JSON parsing failed'
          rescue StandardError
            raise SecurityReportParserError, "#{report.type} security report parsing failed"
          end

          private

          attr_reader :json_data, :report, :validate, :project

          # PostgreSQL can not save texts with unicode null character
          # that's why we are escaping that character.
          def sanitize_json_data
            return unless json_data.gsub!(/(?<!\\)(?:\\\\)*\\u0000/, '\\\\\u0000')

            report.add_warning('Parsing', 'Report artifact contained unicode null characters which are escaped during the ingestion.')
          end

          def valid?
            return true unless validate

            schema_validation_passed = schema_validator.valid?

            schema_validator.errors.each { |error| report.add_error('Schema', error) }
            schema_validator.deprecation_warnings.each { |deprecation_warning| report.add_warning('Schema', deprecation_warning) }
            schema_validator.warnings.each { |warning| report.add_warning('Schema', warning) }

            schema_validation_passed
          end

          def schema_validator
            @schema_validator ||= ::Gitlab::Ci::Parsers::Security::Validators::SchemaValidator.new(
              report.type,
              report_data,
              report.version,
              project: @project,
              scanner: top_level_scanner_data
            )
          end

          # New Oj parsers are not thread safe, therefore,
          # we need to initialize them for each thread.
          def introspect_parser
            Thread.current[:introspect_parser] ||= Oj::Introspect.new(filter: "remediations")
          end

          def report_data
            @report_data ||= introspect_parser.parse(json_data)
          end

          def report_version
            @report_version ||= report_data['version']
          end

          def top_level_scanner_data
            @top_level_scanner_data ||= report_data.dig('scan', 'scanner')
          end

          def scan_data
            @scan_data ||= report_data['scan']
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
            flags = create_flags(data['flags'])
            links = create_links(data['links'])
            location = create_location(data['location'] || {})
            evidence = create_evidence(data['evidence'])
            signatures = create_signatures(tracking_data(data))

            if @signatures_enabled && !signatures.empty?
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
                location: location,
                evidence: evidence,
                severity: ::Enums::Vulnerability.parse_severity_level(data['severity']),
                confidence: ::Enums::Vulnerability.parse_confidence_level(data['confidence']),
                scanner: create_scanner(top_level_scanner_data || data['scanner']),
                scan: report&.scan,
                identifiers: identifiers,
                flags: flags,
                links: links,
                remediations: remediations,
                original_data: data,
                metadata_version: report_version,
                details: data['details'] || {},
                signatures: signatures,
                project_id: @project.id,
                found_by_pipeline: report.pipeline,
                vulnerability_finding_signatures_enabled: @signatures_enabled,
                cvss: data['cvss_vectors'] || []
              )
            )
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

              signature if signature.valid?
            end.compact
          end

          def create_scan
            return unless scan_data.is_a?(Hash)

            report.add_scan(::Gitlab::Ci::Reports::Security::Scan.new(scan_data))
          end

          def set_report_version
            report.version = report_version
          end

          def create_analyzer
            return unless analyzer_data.is_a?(Hash)

            params = {
              id: analyzer_data['id'],
              name: analyzer_data['name'],
              version: analyzer_data['version'],
              vendor: analyzer_data.dig('vendor', 'name')
            }

            return unless params.values.all?

            report.analyzer = ::Gitlab::Ci::Reports::Security::Analyzer.new(**params)
          end

          def create_scanner(scanner_data)
            return unless scanner_data.is_a?(Hash)

            report.add_scanner(
              ::Gitlab::Ci::Reports::Security::Scanner.new(
                external_id: scanner_data['id'],
                name: scanner_data['name'],
                vendor: scanner_data.dig('vendor', 'name'),
                version: scanner_data['version'],
                primary_identifiers: create_scan_primary_identifiers))
          end

          # TODO: primary_identifiers should be initialized on the
          # scan itself but we do not currently parse scans through `MergeReportsService`
          def create_scan_primary_identifiers
            return unless scan_data.is_a?(Hash) && scan_data['primary_identifiers']

            scan_data['primary_identifiers'].map do |identifier|
              ::Gitlab::Ci::Reports::Security::Identifier.new(
                external_type: identifier['type'],
                external_id: identifier['value'],
                name: identifier['name'],
                url: identifier['url'])
            end
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

          def create_flags(flags)
            return [] unless flags.is_a?(Array)

            flags.map { |flag| create_flag(flag) }.compact
          end

          def create_flag(flag)
            return unless flag.is_a?(Hash)

            ::Gitlab::Ci::Reports::Security::Flag.new(type: flag['type'], origin: flag['origin'], description: flag['description'])
          end

          def create_links(links)
            return [] unless links.is_a?(Array)

            links.map { |link| create_link(link) }.compact
          end

          def create_link(link)
            return unless link.is_a?(Hash)

            ::Gitlab::Ci::Reports::Security::Link.new(name: link['name'], url: link['url'])
          end

          def create_location(location_data)
            raise NotImplementedError
          end

          def create_evidence(evidence_data)
            return unless evidence_data.is_a?(Hash)

            ::Gitlab::Ci::Reports::Security::Evidence.new(data: evidence_data)
          end

          def finding_name(data, identifiers, location)
            return data['name'] if data['name'].present?

            identifier = identifiers.find(&:cve?) || identifiers.find(&:cwe?) || identifiers.first

            if location&.fingerprint_path
              "#{identifier.name} in #{location.fingerprint_path}"
            else
              identifier.name.to_s
            end
          end

          def calculate_uuid_v5(primary_identifier, location_fingerprint)
            uuid_v5_name_components = {
              report_type: report.type,
              primary_identifier_fingerprint: primary_identifier&.fingerprint,
              location_fingerprint: location_fingerprint,
              project_id: @project.id
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
