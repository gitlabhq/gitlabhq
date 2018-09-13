# frozen_string_literal: true

module Gitlab
  module Ci
    module External
      class Processor
        FileError = Class.new(StandardError)

        def initialize(values, project, sha)
          @values = values
          @external_files = Gitlab::Ci::External::Mapper.new(values, project, sha).process
          @content = {}
        end

        def perform
          return values if external_files.empty?

          external_files.each do |external_file|
            validate_external_file(external_file)
            @content.deep_merge!(content_of(external_file))
          end

          append_inline_content
          remove_include_keyword
        end

        private

        attr_reader :values, :external_files, :content

        def validate_external_file(external_file)
          unless external_file.valid?
            raise FileError, external_file.error_message
          end
        end

        def content_of(external_file)
          Gitlab::Ci::Config::Loader.new(external_file.content).load!
        end

        def append_inline_content
          @content.deep_merge!(@values)
        end

        def remove_include_keyword
          content.delete(:include)
          content
        end
      end
    end
  end
end
