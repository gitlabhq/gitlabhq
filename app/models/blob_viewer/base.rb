module BlobViewer
  class Base
    class_attribute :partial_name, :type, :extensions, :client_side, :text_based, :switcher_icon, :switcher_title, :max_size, :absolute_max_size

    delegate :partial_path, :rich?, :simple?, :client_side?, :text_based?, to: :class

    attr_reader :blob

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

    def server_side?
      !client_side?
    end

    def self.text_based?
      text_based
    end

    def self.can_render?(blob)
      !extensions || extensions.include?(blob.extension)
    end

    def can_override_max_size?
      too_large? && !too_large?(override_max_size: true)
    end

    def relevant_max_size
      if too_large?(override_max_size: true)
        absolute_max_size
      elsif too_large?
        max_size
      end
    end

    def render_error(override_max_size: false)
      if too_large?(override_max_size: override_max_size)
        :too_large
      elsif server_side_but_stored_in_lfs?
        :server_side_but_stored_in_lfs
      end
    end

    def prepare!
      if server_side? && blob.project
        blob.load_all_data!(blob.project.repository)
      end
    end

    private

    def too_large?(override_max_size: false)
      if override_max_size
        blob.raw_size > absolute_max_size
      else
        blob.raw_size > max_size
      end
    end

    def server_side_but_stored_in_lfs?
      !client_side? && blob.valid_lfs_pointer?
    end
  end
end
