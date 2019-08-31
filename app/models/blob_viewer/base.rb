# frozen_string_literal: true

module BlobViewer
  class Base
    PARTIAL_PATH_PREFIX = 'projects/blob/viewers'

    class_attribute :partial_name, :loading_partial_name, :type, :extensions, :file_types, :load_async, :binary, :switcher_icon, :switcher_title, :collapse_limit, :size_limit

    self.loading_partial_name = 'loading'

    delegate :partial_path, :loading_partial_path, :rich?, :simple?, :load_async?, :text?, :binary?, to: :class

    attr_reader :blob

    delegate :project, to: :blob

    def initialize(blob)
      @blob = blob
      @initially_binary = blob.binary_in_repo?
    end

    def self.partial_path
      File.join(PARTIAL_PATH_PREFIX, partial_name)
    end

    def self.loading_partial_path
      File.join(PARTIAL_PATH_PREFIX, loading_partial_name)
    end

    def self.rich?
      type == :rich
    end

    def self.simple?
      type == :simple
    end

    def self.auxiliary?
      type == :auxiliary
    end

    def self.load_async?
      load_async
    end

    def self.binary?
      binary
    end

    def self.text?
      !binary?
    end

    def self.can_render?(blob, verify_binary: true)
      return false if verify_binary && binary? != blob.binary_in_repo?
      return true if extensions&.include?(blob.extension)
      return true if file_types&.include?(blob.file_type)

      false
    end

    def collapsed?
      return @collapsed if defined?(@collapsed)

      @collapsed = !blob.expanded? && collapse_limit && blob.raw_size > collapse_limit
    end

    def too_large?
      return @too_large if defined?(@too_large)

      @too_large = size_limit && blob.raw_size > size_limit
    end

    def binary_detected_after_load?
      !@initially_binary && blob.binary_in_repo?
    end

    # This method is used on the server side to check whether we can attempt to
    # render the blob at all. Human-readable error messages are found in the
    # `BlobHelper#blob_render_error_reason` helper.
    #
    # This method does not and should not load the entire blob contents into
    # memory, and should not be overridden to do so in order to validate the
    # format of the blob.
    #
    # Prefer to implement a client-side viewer, where the JS component loads the
    # binary from `blob_raw_path` and does its own format validation and error
    # rendering, especially for potentially large binary formats.
    def render_error
      if too_large?
        :too_large
      elsif collapsed?
        :collapsed
      end
    end

    def prepare!
      # To be overridden by subclasses
    end
  end
end
