# frozen_string_literal: true

module Types
  module Ci
    class JobArtifactFileTypeEnum < BaseEnum
      graphql_name 'JobArtifactFileType'

      ::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.keys.each do |file_type|
        value file_type.to_s.upcase, value: file_type.to_s
      end
    end
  end
end
