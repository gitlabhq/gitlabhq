# frozen_string_literal: true

module Ci
  class ParseAnnotationsArtifactService < ::BaseService
    include ::Gitlab::Utils::StrongMemoize
    include ::Gitlab::EncodingHelper

    SizeLimitError = Class.new(StandardError)
    ParserError = Class.new(StandardError)

    def execute(artifact)
      return error('Artifact is not annotations file type', :bad_request) unless artifact&.annotations?

      return error("Annotations Artifact Too Big. Maximum Allowable Size: #{annotations_size_limit}", :bad_request) if
        artifact.file.size > annotations_size_limit

      annotations = parse!(artifact)
      Ci::JobAnnotation.bulk_upsert!(annotations, unique_by: %i[partition_id job_id name])

      success
    rescue SizeLimitError, ParserError, Gitlab::Json.parser_error, ActiveRecord::RecordInvalid => error
      error(error.message, :bad_request)
    end

    private

    def parse!(artifact)
      annotations = []

      artifact.each_blob do |blob|
        # Windows powershell may output UTF-16LE files, so convert the whole file
        # to UTF-8 before proceeding.
        blob = strip_bom(encode_utf8_with_replacement_character(blob))

        blob_json = Gitlab::Json.parse(blob)
        raise ParserError, 'Annotations files must be a JSON object' unless blob_json.is_a?(Hash)

        blob_json.each do |key, value|
          annotations.push(Ci::JobAnnotation.new(job: artifact.job, name: key, data: value,
            project_id: project.id))

          if annotations.size > annotations_num_limit
            raise SizeLimitError,
              "Annotations files cannot have more than #{annotations_num_limit} annotation lists"
          end
        end
      end

      annotations
    end

    def annotations_num_limit
      project.actual_limits.ci_job_annotations_num
    end
    strong_memoize_attr :annotations_num_limit

    def annotations_size_limit
      project.actual_limits.ci_job_annotations_size
    end
    strong_memoize_attr :annotations_size_limit
  end
end
