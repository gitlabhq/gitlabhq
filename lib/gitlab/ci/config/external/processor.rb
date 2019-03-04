# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Processor
          IncludeError = Class.new(StandardError)

          def initialize(values, project:, sha:, user:, expandset:)
            @values = values
            @external_files = External::Mapper.new(values, project: project, sha: sha, user: user, expandset: expandset).process
            @content = {}
          rescue External::Mapper::Error => e
            raise IncludeError, e.message
          end

          def perform
            return @values if @external_files.empty?

            validate_external_files!
            merge_external_files!
            append_inline_content!
            remove_include_keyword!
          end

          private

          def validate_external_files!
            @external_files.each do |file|
              raise IncludeError, file.error_message unless file.valid?
            end
          end

          def merge_external_files!
            @external_files.each do |file|
              @content.deep_merge!(file.to_hash)
            end
          end

          def append_inline_content!
            @content.deep_merge!(@values)
          end

          def remove_include_keyword!
            @content.tap { @content.delete(:include) }
          end
        end
      end
    end
  end
end
