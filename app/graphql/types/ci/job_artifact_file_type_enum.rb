# frozen_string_literal: true

module Types
  module Ci
    class JobArtifactFileTypeEnum < BaseEnum
      graphql_name 'JobArtifactFileType'

      ::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.keys.each do |file_type|
        description = file_type == :codequality ? "CODE QUALITY" : file_type.to_s.titleize.upcase  # This is needed as doc lint will not allow codequality as one word
        value file_type.to_s.upcase, value: file_type.to_s, description: "#{description} job artifact file type."
      end
    end
  end
end
