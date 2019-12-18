# frozen_string_literal: true

require_dependency 'gitlab/encoding_helper'

module Gitlab
  module Git
    # The ID of empty tree.
    # See http://stackoverflow.com/a/40884093/1856239 and
    # https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
    EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
    BLANK_SHA = ('0' * 40).freeze
    COMMIT_ID = /\A[0-9a-f]{40}\z/.freeze
    TAG_REF_PREFIX = "refs/tags/"
    BRANCH_REF_PREFIX = "refs/heads/"

    BaseError = Class.new(StandardError)
    CommandError = Class.new(BaseError)
    CommitError = Class.new(BaseError)
    OSError = Class.new(BaseError)
    UnknownRef = Class.new(BaseError)

    class << self
      include Gitlab::EncodingHelper

      def ref_name(ref)
        encode!(ref).sub(%r{\Arefs/(tags|heads|remotes)/}, '')
      end

      def branch_name(ref)
        ref = ref.to_s
        if self.branch_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
      end

      def committer_hash(email:, name:)
        return if email.nil? || name.nil?

        {
          email: email,
          name: name,
          time: Time.now
        }
      end

      def tag_name(ref)
        ref = ref.to_s
        if self.tag_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
      end

      def tag_ref?(ref)
        ref =~ /^#{TAG_REF_PREFIX}.+/
      end

      def branch_ref?(ref)
        ref =~ /^#{BRANCH_REF_PREFIX}.+/
      end

      def blank_ref?(ref)
        ref == BLANK_SHA
      end

      def commit_id?(ref)
        COMMIT_ID.match?(ref)
      end

      def version
        Gitlab::Git::Version.git_version
      end

      def check_namespace!(*objects)
        expected_namespace = self.name + '::'
        objects.each do |object|
          unless object.class.name.start_with?(expected_namespace)
            raise ArgumentError, "expected object in #{expected_namespace}, got #{object}"
          end
        end
      end

      def diff_line_code(file_path, new_line_position, old_line_position)
        "#{Digest::SHA1.hexdigest(file_path)}_#{old_line_position}_#{new_line_position}"
      end

      def shas_eql?(sha1, sha2)
        return true if sha1.nil? && sha2.nil?
        return false if sha1.nil? || sha2.nil?
        return false unless sha1.class == sha2.class

        # If either of the shas is below the minimum length, we cannot be sure
        # that they actually refer to the same commit because of hash collision.
        length = [sha1.length, sha2.length].min
        return false if length < Gitlab::Git::Commit::MIN_SHA_LENGTH

        sha1[0, length] == sha2[0, length]
      end
    end
  end
end
