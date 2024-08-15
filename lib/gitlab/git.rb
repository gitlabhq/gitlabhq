# frozen_string_literal: true

require_relative 'encoding_helper'

module Gitlab
  module Git
    # The ID of empty tree.
    # https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
    SHA1_EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
    SHA256_EMPTY_TREE_ID = '6ef19b41225c5369f1c104d45d8d85efa9b057b53b14b4b9b939dd74decc5321'
    SHA1_BLANK_SHA = ('0' * 40).freeze
    SHA256_BLANK_SHA = ('0' * 64).freeze
    COMMIT_ID = /\A#{Gitlab::Git::Commit::RAW_FULL_SHA_PATTERN}\z/
    TAG_REF_PREFIX = "refs/tags/"
    BRANCH_REF_PREFIX = "refs/heads/"
    SHA_LIKE_REF = %r{\A(#{TAG_REF_PREFIX}|#{BRANCH_REF_PREFIX})#{Gitlab::Git::Commit::RAW_FULL_SHA_PATTERN}\z}

    # NOTE: We don't use linguist anymore, but we'd still want to support it
    # to be backward/GitHub compatible. Using `gitlab-*` prefixed overrides
    # going forward would give us a better control and flexibility.
    ATTRIBUTE_OVERRIDES = {
      generated: %w[gitlab-generated linguist-generated]
    }.freeze

    CommandError = Class.new(BaseError)
    CommitError = Class.new(BaseError)
    OSError = Class.new(BaseError)
    AmbiguousRef = Class.new(BaseError)
    CommandTimedOut = Class.new(CommandError)
    InvalidPageToken = Class.new(BaseError)
    InvalidRefFormatError = Class.new(BaseError)
    ReferencesLockedError = Class.new(BaseError)
    ReferenceStateMismatchError = Class.new(BaseError)

    class ResourceExhaustedError < BaseError
      def initialize(msg = nil, retry_after = 0)
        super(msg)
        @retry_after = retry_after
      end

      def headers
        if @retry_after.to_i > 0
          { "Retry-After" => @retry_after }
        else
          {}
        end
      end
    end

    class ReferenceNotFoundError < BaseError
      attr_reader :name

      def initialize(msg = nil, name = "")
        super(msg)
        @name = name
      end
    end

    class << self
      include Gitlab::EncodingHelper

      def ref_name(ref, types: 'tags|heads|remotes')
        encode_utf8_with_escaping!(ref).sub(%r{\Arefs/(#{types})/}, '')
      end

      def branch_name(ref)
        ref = ref.to_s
        if self.branch_ref?(ref)
          self.ref_name(ref)
        else
          nil
        end
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
        ref =~ /^#{TAG_REF_PREFIX}.+/o
      end

      def branch_ref?(ref)
        ref =~ /^#{BRANCH_REF_PREFIX}.+/o
      end

      def blank_ref?(ref)
        ref == SHA1_BLANK_SHA || ref == SHA256_BLANK_SHA
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
        return false unless sha1.instance_of?(sha2.class)

        # If either of the shas is below the minimum length, we cannot be sure
        # that they actually refer to the same commit because of hash collision.
        length = [sha1.length, sha2.length].min
        return false if length < Gitlab::Git::Commit::MIN_SHA_LENGTH

        # Optimization: prevent unnecessary substring creation
        if sha1.length == sha2.length
          sha1 == sha2
        else
          sha1[0, length] == sha2[0, length]
        end
      end
    end
  end
end
