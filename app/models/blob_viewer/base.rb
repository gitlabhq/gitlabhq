module BlobViewer
  class Base
    PARTIAL_PATH_PREFIX = 'projects/blob/viewers'.freeze

    class_attribute :partial_name, :loading_partial_name, :type, :extensions, :file_types, :client_side, :binary, :switcher_icon, :switcher_title, :max_size, :absolute_max_size

    self.loading_partial_name = 'loading'

    delegate :partial_path, :loading_partial_path, :rich?, :simple?, :client_side?, :server_side?, :text?, :binary?, to: :class

    attr_reader :blob
    attr_accessor :override_max_size

    def initialize(blob)
      @blob = blob
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

    def self.client_side?
      client_side
    end

    def self.server_side?
      !client_side?
    end

    def self.binary?
      binary
    end

    def self.text?
      !binary?
    end

    def self.can_render?(blob, verify_binary: true)
      return false if verify_binary && binary? != blob.binary?
      return true if extensions&.include?(blob.extension)
      return true if file_types&.include?(Gitlab::FileDetector.type_of(blob.path))

      false
    end

    def too_large?
      max_size && blob.raw_size > max_size
    end

    def absolutely_too_large?
      absolute_max_size && blob.raw_size > absolute_max_size
    end

    def can_override_max_size?
      too_large? && !absolutely_too_large?
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
    # binary from `blob_raw_url` and does its own format validation and error
    # rendering, especially for potentially large binary formats.
    def render_error
      return @render_error if defined?(@render_error)

      @render_error =
        if server_side_but_stored_externally?
          # Files that are not stored in the repository, like LFS files and
          # build artifacts, can only be rendered using a client-side viewer,
          # since we do not want to read large amounts of data into memory on the
          # server side. Client-side viewers use JS and can fetch the file from
          # `blob_raw_url` using AJAX.
          :server_side_but_stored_externally
        elsif override_max_size ? absolutely_too_large? : too_large?
          :too_large
        end
    end

    def prepare!
      # To be overridden by subclasses
    end

    private

    def server_side_but_stored_externally?
      server_side? && blob.stored_externally?
    end
  end
end
