# Blob is a Rails-specific wrapper around Gitlab::Git::Blob objects
class Blob < SimpleDelegator
  CACHE_TIME = 60 # Cache raw blobs referred to by a (mutable) ref for 1 minute
  CACHE_TIME_IMMUTABLE = 3600 # Cache blobs referred to by an immutable reference for 1 hour

  MAXIMUM_TEXT_HIGHLIGHT_SIZE = 1.megabyte

  RICH_VIEWERS = [
    BlobViewer::Image,
    BlobViewer::PDF,
    BlobViewer::Sketch,
    BlobViewer::BinarySTL,
    BlobViewer::TextSTL,
    BlobViewer::Notebook,
    BlobViewer::SVG,
    BlobViewer::Markup,
  ].freeze

  attr_reader :project

  # Wrap a Gitlab::Git::Blob object, or return nil when given nil
  #
  # This method prevents the decorated object from evaluating to "truthy" when
  # given a nil value. For example:
  #
  #     blob = Blob.new(nil)
  #     puts "truthy" if blob # => "truthy"
  #
  #     blob = Blob.decorate(nil)
  #     puts "truthy" if blob # No output
  def self.decorate(blob, project = nil)
    return if blob.nil?

    new(blob, project)
  end

  def initialize(blob, project = nil)
    @project = project

    super(blob)
  end

  # Returns the data of the blob.
  #
  # If the blob is a text based blob the content is converted to UTF-8 and any
  # invalid byte sequences are replaced.
  def data
    if binary?
      super
    else
      @data ||= super.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end
  end

  def no_highlighting?
    size && size > MAXIMUM_TEXT_HIGHLIGHT_SIZE
  end

  def too_large?
    size && truncated?
  end

  # Returns the size of the file that this blob represents. If this blob is an
  # LFS pointer, this is the size of the file stored in LFS. Otherwise, this is
  # the size of the blob itself.
  def raw_size
    if valid_lfs_pointer?
      lfs_size
    else
      size
    end
  end

  # Returns whether the file that this blob represents is binary. If this blob is
  # an LFS pointer, we assume the file stored in LFS is binary, unless a
  # text-based rich blob viewer matched on the file's extension. Otherwise, this
  # depends on the type of the blob itself.
  def raw_binary?
    if valid_lfs_pointer?
      if rich_viewer
        rich_viewer.binary?
      else
        true
      end
    else
      binary?
    end
  end

  def extension
    @extension ||= extname.downcase.delete('.')
  end

  def video?
    UploaderHelper::VIDEO_EXT.include?(extension)
  end

  def readable_text?
    text? && !valid_lfs_pointer? && !too_large?
  end

  def valid_lfs_pointer?
    lfs_pointer? && project.lfs_enabled?
  end

  def invalid_lfs_pointer?
    lfs_pointer? && !project.lfs_enabled?
  end

  def simple_viewer
    @simple_viewer ||= simple_viewer_class.new(self)
  end

  def rich_viewer
    return @rich_viewer if defined?(@rich_viewer)

    @rich_viewer = rich_viewer_class&.new(self)
  end

  def rendered_as_text?(ignore_errors: true)
    simple_viewer.text? && (ignore_errors || simple_viewer.render_error.nil?)
  end

  def show_viewer_switcher?
    rendered_as_text? && rich_viewer
  end

  def override_max_size!
    simple_viewer&.override_max_size = true
    rich_viewer&.override_max_size = true
  end

  private

  def simple_viewer_class
    if empty?
      BlobViewer::Empty
    elsif raw_binary?
      BlobViewer::Download
    else # text
      BlobViewer::Text
    end
  end

  def rich_viewer_class
    return if invalid_lfs_pointer? || empty?

    classes =
      if valid_lfs_pointer?
        RICH_VIEWERS
      elsif binary?
        RICH_VIEWERS.select(&:binary?)
      else # text
        RICH_VIEWERS.select(&:text?)
      end

    classes.find { |viewer_class| viewer_class.can_render?(self) }
  end
end
