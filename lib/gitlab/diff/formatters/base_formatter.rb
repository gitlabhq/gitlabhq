module Gitlab
  module Diff
    module Formatters
      class BaseFormatter
        attr_reader :old_path
        attr_reader :new_path
        attr_reader :base_sha
        attr_reader :start_sha
        attr_reader :head_sha
        attr_reader :position_type

        def initialize(attrs)
          if diff_file = attrs[:diff_file]
            attrs[:diff_refs] = diff_file.diff_refs
            attrs[:old_path] = diff_file.old_path
            attrs[:new_path] = diff_file.new_path
          end

          if diff_refs = attrs[:diff_refs]
            attrs[:base_sha] = diff_refs.base_sha
            attrs[:start_sha] = diff_refs.start_sha
            attrs[:head_sha]  = diff_refs.head_sha
          end

          @old_path = attrs[:old_path]
          @new_path = attrs[:new_path]
          @base_sha = attrs[:base_sha]
          @start_sha = attrs[:start_sha]
          @head_sha  = attrs[:head_sha]
        end

        def key
          [base_sha, start_sha, head_sha, Digest::SHA1.hexdigest(old_path || ""), Digest::SHA1.hexdigest(new_path || "")]
        end

        def to_h
          {
            base_sha: base_sha,
            start_sha: start_sha,
            head_sha: head_sha,
            old_path: old_path,
            new_path: new_path,
            position_type: position_type
          }
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
