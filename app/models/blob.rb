# Blob is a Rails-specific wrapper around Gitlab::Git::Blob objects
class Blob < SimpleDelegator
  CACHE_TIME = 60 # Cache raw blobs referred to by a (mutable) ref for 1 minute
  CACHE_TIME_IMMUTABLE = 3600 # Cache blobs referred to by an immutable reference for 1 hour

  MAXIMUM_TEXT_HIGHLIGHT_SIZE = 1.megabyte

  # Finding a viewer for a blob happens based only on extension and whether the
  # blob is binary or text, which means 1 blob should only be matched by 1 viewer,
  # and the order of these viewers doesn't really matter.
  #
  # However, when the blob is an LFS pointer, we cannot know for sure whether the
  # file being pointed to is binary or text. In this case, we match only on
  # extension, preferring binary viewers over text ones if both exist, since the
  # large files referred to in "Large File Storage" are much more likely to be
  # binary than text.
  #
  # `.stl` files, for example, exist in both binary and text forms, and are
  # handled by different viewers (`BinarySTL` and `TextSTL`) depending on blob
  # type. LFS pointers to `.stl` files are assumed to always be the binary kind,
  # and use the `BinarySTL` viewer.
  RICH_VIEWERS = [
    BlobViewer::Markup,
    BlobViewer::Notebook,
    BlobViewer::SVG,

    BlobViewer::Image,
    BlobViewer::Sketch,
    BlobViewer::Balsamiq,

    BlobViewer::Video,

    BlobViewer::PDF,

    BlobViewer::BinarySTL,
    BlobViewer::TextSTL
<<<<<<< HEAD
  ].freeze
=======
  ].sort_by { |v| v.binary? ? 0 : 1 }.freeze

  AUXILIARY_VIEWERS = [
    BlobViewer::GitlabCiYml,
    BlobViewer::RouteMap,
>>>>>>> upstream/master

    BlobViewer::License,
    BlobViewer::Contributing
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
    raw_size && raw_size > MAXIMUM_TEXT_HIGHLIGHT_SIZE
  end

  def empty?
    raw_size == 0
  end

  def too_large?
    size && truncated?
  end

  def external_storage_error?
    if external_storage == :lfs
      !project&.lfs_enabled?
    else
      false
    end
  end

  def stored_externally?
    return @stored_externally if defined?(@stored_externally)

    @stored_externally = external_storage && !external_storage_error?
  end

  # Returns the size of the file that this blob represents. If this blob is an
  # LFS pointer, this is the size of the file stored in LFS. Otherwise, this is
  # the size of the blob itself.
  def raw_size
    if stored_externally?
      external_size
    else
      size
    end
  end

  # Returns whether the file that this blob represents is binary. If this blob is
  # an LFS pointer, we assume the file stored in LFS is binary, unless a
  # text-based rich blob viewer matched on the file's extension. Otherwise, this
  # depends on the type of the blob itself.
  def raw_binary?
    if stored_externally?
      if rich_viewer
        rich_viewer.binary?
      elsif Linguist::Language.find_by_filename(name).any?
        false
      elsif _mime_type
        _mime_type.binary?
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
    text? && !stored_externally? && !too_large?
  end

  def simple_viewer
    @simple_viewer ||= simple_viewer_class.new(self)
  end

  def rich_viewer
    return @rich_viewer if defined?(@rich_viewer)

    @rich_viewer = rich_viewer_class&.new(self)
  end

  def auxiliary_viewer
    return @auxiliary_viewer if defined?(@auxiliary_viewer)

    @auxiliary_viewer = auxiliary_viewer_class&.new(self)
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
    viewer_class_from(RICH_VIEWERS)
  end

  def auxiliary_viewer_class
    viewer_class_from(AUXILIARY_VIEWERS)
  end

  def viewer_class_from(classes)
    return if empty? || external_storage_error?

    verify_binary = !stored_externally?

    classes.find { |viewer_class| viewer_class.can_render?(self, verify_binary: verify_binary) }
  end
end
