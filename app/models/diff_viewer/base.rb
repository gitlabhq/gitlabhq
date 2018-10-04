# frozen_string_literal: true

module DiffViewer
  class Base
    PARTIAL_PATH_PREFIX = 'projects/diffs/viewers'.freeze

    class_attribute :partial_name, :type, :extensions, :file_types, :binary, :switcher_icon, :switcher_title

    # These limits relate to the sum of the old and new blob sizes.
    # Limits related to the actual size of the diff are enforced in Gitlab::Diff::File.
    class_attribute :collapse_limit, :size_limit

    delegate :partial_path, :loading_partial_path, :rich?, :simple?, :text?, :binary?, to: :class

    attr_reader :diff_file

    delegate :project, to: :diff_file

    def initialize(diff_file)
      @diff_file = diff_file
      @initially_binary = diff_file.binary?
    end

    def self.partial_path
      File.join(PARTIAL_PATH_PREFIX, partial_name)
    end

    def self.rich?
      type == :rich
    end

    def self.simple?
      type == :simple
    end

    def self.binary?
      binary
    end

    def self.text?
      !binary?
    end

    def self.can_render?(diff_file, verify_binary: true)
      can_render_blob?(diff_file.old_blob, verify_binary: verify_binary) &&
        can_render_blob?(diff_file.new_blob, verify_binary: verify_binary)
    end

    def self.can_render_blob?(blob, verify_binary: true)
      return true if blob.nil?
      return false if verify_binary && binary? != blob.binary?
      return true if extensions&.include?(blob.extension)
      return true if file_types&.include?(blob.file_type)

      false
    end

    def collapsed?
      return @collapsed if defined?(@collapsed)
      return @collapsed = true if diff_file.collapsed?

      @collapsed = !diff_file.expanded? && collapse_limit && diff_file.raw_size > collapse_limit
    end

    def too_large?
      return @too_large if defined?(@too_large)
      return @too_large = true if diff_file.too_large?

      @too_large = size_limit && diff_file.raw_size > size_limit
    end

    def binary_detected_after_load?
      !@initially_binary && diff_file.binary?
    end

    # This method is used on the server side to check whether we can attempt to
    # render the diff_file at all. Human-readable error messages are found in the
    # `BlobHelper#diff_render_error_reason` helper.
    def render_error
      if too_large?
        :too_large
      end
    end

    def prepare!
      # To be overridden by subclasses
    end
  end
end
