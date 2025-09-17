# frozen_string_literal: true

module SupplyChain
  module Slsa
    module CamelCaseJson
      def deep_change_case(json)
        exceptions = %w[_type variables]

        new_json = {}
        json.each do |key, value|
          key = key.camelize(:lower) if exceptions.exclude?(key)
          value = deep_change_case(value) if value.is_a?(Hash) && exceptions.exclude?(key)

          new_json[key] = value
        end

        new_json
      end
    end

    class ProvenanceStatement
      include ActiveModel::Serializers::JSON
      include CamelCaseJson

      attr_accessor :_type, :subject, :predicate_type, :predicate

      def self.from_build(build)
        archives = build.job_artifacts.filter { |artifact| artifact.file_type == "archive" }
        raise ArgumentError, 'artifacts associated with build do not contain a single archive' if archives.length != 1

        archive = archives[0]
        archive_resource = ResourceDescriptor.new(name: archive.file.filename, digest: { sha256: archive.file_sha256 })

        provenance_statement = ProvenanceStatement.new
        provenance_statement.subject = [archive_resource]
        provenance_statement.predicate = Predicate.from_build(build)

        provenance_statement
      end

      def initialize
        @_type = "https://in-toto.io/Statement/v1"
        @predicate_type = "https://slsa.dev/provenance/v1"
      end

      def as_json(options = nil)
        deep_change_case(super)
      end

      def attributes
        { '_type' => nil, 'subject' => nil, 'predicate_type' => nil, 'predicate' => nil }
      end

      class BuildDefinition
        include ActiveModel::Model

        attr_accessor :build_type, :external_parameters, :internal_parameters, :resolved_dependencies

        def self.from_build(build)
          build_type = "https://docs.gitlab.com/ci/pipeline_security/slsa/provenance_v1"
          external_parameters = ExternalParameters.from_build(build)
          internal_parameters = {
            architecture: build.runner_manager.architecture,
            executor: build.runner_manager.executor_type,
            job: build.id,
            name: build.runner.display_name
          }

          build_resource = ResourceDescriptor.new(uri: Gitlab::Routing.url_helpers.project_url(build.project),
            digest: { gitCommit: build.sha })
          resolved_dependencies = [build_resource]

          BuildDefinition.new(build_type: build_type, external_parameters: external_parameters,
            internal_parameters: internal_parameters,
            resolved_dependencies: resolved_dependencies)
        end
      end

      class RunDetails
        include ActiveModel::Model

        attr_accessor :builder, :metadata, :byproducts

        def self.from_build(build)
          builder = {
            id: Gitlab::Routing.url_helpers.project_runner_url(build.project, build.runner),
            version: {
              "gitlab-runner": build.runner_manager.revision
            }
          }

          metadata = {
            invocationId: build.id.to_s,
            # https://github.com/in-toto/attestation/blob/7aefca35a0f74a6e0cb397a8c4a76558f54de571/spec/v1/field_types.md#timestamp
            startedOn: build.started_at&.utc&.rfc3339,
            finishedOn: build.finished_at&.utc&.rfc3339
          }

          RunDetails.new(builder: builder, metadata: metadata)
        end
      end

      class ExternalParameters
        include ActiveModel::Model

        attr_accessor :source, :entry_point, :variables

        def self.from_build(build)
          source = Gitlab::Routing.url_helpers.project_url(build.project)
          entry_point = build.name

          variables = {}
          build.variables.each do |variable|
            variables[variable.key] = if variable.masked?
                                        '[MASKED]'
                                      else
                                        variable.value
                                      end
          end

          ExternalParameters.new(source: source, entry_point: entry_point, variables: variables)
        end
      end

      class Builder
        include ActiveModel::Model

        attr_accessor :id, :builder_dependencies, :version
      end

      class BuildMetadata
        include ActiveModel::Model

        attr_accessor :invocation_id, :started_on, :finished_on
      end

      class Predicate
        include ActiveModel::Model
        include CamelCaseJson

        def self.from_build(build)
          raise ArgumentError, "runner manager information not available in build" unless build.runner_manager

          predicate = Predicate.new
          predicate.build_definition = BuildDefinition.from_build(build)
          predicate.run_details = RunDetails.from_build(build)

          predicate
        end

        def as_json(options = nil)
          deep_change_case(super)
        end

        attr_accessor :build_definition, :run_details
      end
    end
  end
end
