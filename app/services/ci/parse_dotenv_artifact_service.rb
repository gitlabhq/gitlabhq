# frozen_string_literal: true

module Ci
  class ParseDotenvArtifactService < ::BaseService
    MAX_ACCEPTABLE_DOTENV_SIZE = 5.kilobytes
    MAX_ACCEPTABLE_VARIABLES_COUNT = 20

    SizeLimitError = Class.new(StandardError)
    ParserError = Class.new(StandardError)

    def execute(artifact)
      validate!(artifact)

      variables = parse!(artifact)
      Ci::JobVariable.bulk_insert!(variables)

      success
    rescue SizeLimitError, ParserError, ActiveRecord::RecordInvalid => error
      Gitlab::ErrorTracking.track_exception(error, job_id: artifact.job_id)
      error(error.message, :bad_request)
    end

    private

    def validate!(artifact)
      unless artifact&.dotenv?
        raise ArgumentError, 'Artifact is not dotenv file type'
      end

      unless artifact.file.size < MAX_ACCEPTABLE_DOTENV_SIZE
        raise SizeLimitError,
          "Dotenv Artifact Too Big. Maximum Allowable Size: #{MAX_ACCEPTABLE_DOTENV_SIZE}"
      end
    end

    def parse!(artifact)
      variables = []

      artifact.each_blob do |blob|
        blob.each_line do |line|
          key, value = scan_line!(line)

          variables << Ci::JobVariable.new(job_id: artifact.job_id,
            source: :dotenv, key: key, value: value)
        end
      end

      if variables.size > MAX_ACCEPTABLE_VARIABLES_COUNT
        raise SizeLimitError,
          "Dotenv files cannot have more than #{MAX_ACCEPTABLE_VARIABLES_COUNT} variables"
      end

      variables
    end

    def scan_line!(line)
      result = line.scan(/^(.*?)=(.*)$/).last

      raise ParserError, 'Invalid Format' if result.nil?

      result.each(&:strip!)
    end
  end
end
