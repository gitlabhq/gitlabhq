# frozen_string_literal: true

module Ci
  class ParseDotenvArtifactService < ::BaseService
    include ::Gitlab::Utils::StrongMemoize
    include ::Gitlab::EncodingHelper

    SizeLimitError = Class.new(StandardError)
    ParserError = Class.new(StandardError)

    def execute(artifact)
      validate!(artifact)

      variables = parse!(artifact)
      Ci::JobVariable.bulk_insert!(variables)

      success
    rescue SizeLimitError, ParserError, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
      Gitlab::ErrorTracking.track_exception(error, job_id: artifact.job_id)
      error(error.message, :bad_request)
    end

    private

    def validate!(artifact)
      unless artifact&.dotenv?
        raise ArgumentError, 'Artifact is not dotenv file type'
      end

      unless artifact.file.size < dotenv_size_limit
        raise SizeLimitError,
          "Dotenv Artifact Too Big. Maximum Allowable Size: #{dotenv_size_limit}"
      end
    end

    def parse!(artifact)
      variables = {}

      artifact.each_blob do |blob|
        # Windows powershell may output UTF-16LE files, so convert the whole file
        # to UTF-8 before proceeding.
        blob = strip_bom(encode_utf8_with_replacement_character(blob))

        blob.each_line do |line|
          key, value = scan_line!(line)

          variables[key] = Ci::JobVariable.new(
            job_id: artifact.job_id,
            source: :dotenv,
            key: key,
            value: value,
            raw: false,
            project_id: artifact.project_id
          )
        end
      end

      if variables.size > dotenv_variable_limit
        raise SizeLimitError,
          "Dotenv files cannot have more than #{dotenv_variable_limit} variables"
      end

      variables.values
    end

    def scan_line!(line)
      result = line.scan(/^(.*?)=(.*)$/).last

      raise ParserError, 'Invalid Format' if result.nil?

      result.each(&:strip!)
    end

    def dotenv_variable_limit
      strong_memoize(:dotenv_variable_limit) { project.actual_limits.dotenv_variables }
    end

    def dotenv_size_limit
      strong_memoize(:dotenv_size_limit) { project.actual_limits.dotenv_size }
    end
  end
end
