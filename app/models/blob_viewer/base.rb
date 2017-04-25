module BlobViewer
  class Base
    class_attribute :partial_name, :type, :extensions, :client_side, :binary, :switcher_icon, :switcher_title, :max_size, :absolute_max_size

    delegate :partial_path, :rich?, :simple?, :client_side?, :server_side?, :text?, :binary?, to: :class

    attr_reader :blob
    attr_accessor :override_max_size

    def initialize(blob)
      @blob = blob
    end

    def self.partial_path
      "projects/blob/viewers/#{partial_name}"
    end

    def self.rich?
      type == :rich
    end

    def self.simple?
      type == :simple
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

    def self.can_render?(blob)
      !extensions || extensions.include?(blob.extension)
    end

    def too_large?
      blob.raw_size > max_size
    end

    def absolutely_too_large?
      blob.raw_size > absolute_max_size
    end

    def can_override_max_size?
      too_large? && !absolutely_too_large?
    end

    def render_error
      if server_side_but_stored_in_lfs?
        :server_side_but_stored_in_lfs
      elsif override_max_size ? absolutely_too_large? : too_large?
        :too_large
      end
    end

    def prepare!
      if server_side? && blob.project
        blob.load_all_data!(blob.project.repository)
      end
    end

    private

    def server_side_but_stored_in_lfs?
      server_side? && blob.valid_lfs_pointer?
    end
  end
end
