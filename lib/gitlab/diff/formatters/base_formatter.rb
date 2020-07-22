# frozen_string_literal: true

module Gitlab
  module Diff
    module Formatters
      class BaseFormatter
        attr_reader :old_path
        attr_reader :new_path
        attr_reader :file_identifier_hash
        attr_reader :base_sha
        attr_reader :start_sha
        attr_reader :head_sha

        def initialize(attrs)
          if diff_file = attrs[:diff_file]
            attrs[:diff_refs] = diff_file.diff_refs
            attrs[:old_path] = diff_file.old_path
            attrs[:new_path] = diff_file.new_path
            attrs[:file_identifier_hash] = diff_file.file_identifier_hash
          end

          if diff_refs = attrs[:diff_refs]
            attrs[:base_sha] = diff_refs.base_sha
            attrs[:start_sha] = diff_refs.start_sha
            attrs[:head_sha]  = diff_refs.head_sha
          end

          @old_path = attrs[:old_path]
          @new_path = attrs[:new_path]
          @file_identifier_hash = attrs[:file_identifier_hash]
          @base_sha = attrs[:base_sha]
          @start_sha = attrs[:start_sha]
          @head_sha  = attrs[:head_sha]
        end

        def key
          [base_sha, start_sha, head_sha, Digest::SHA1.hexdigest(old_path || ""), Digest::SHA1.hexdigest(new_path || "")]
        end

        def to_h
          out = {
            base_sha: base_sha,
            start_sha: start_sha,
            head_sha: head_sha,
            old_path: old_path,
            new_path: new_path,
            position_type: position_type
          }

          if Feature.enabled?(:file_identifier_hash)
            out[:file_identifier_hash] = file_identifier_hash
          end

          out
        end

        def position_type
          raise NotImplementedError
        end

        def ==(other)
          raise NotImplementedError
        end

        def complete?
          raise NotImplementedError
        end
      end
    end
  end
end
