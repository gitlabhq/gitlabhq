# frozen_string_literal: true

# Blob is a Rails-specific wrapper around Gitlab::Git::Blob, SnippetBlob and Ci::ArtifactBlob
class Blob < SimpleDelegator
  include Presentable
  include BlobLanguageFromGitAttributes
  include BlobActiveModel

  CACHE_TIME = 60 # Cache raw blobs referred to by a (mutable) ref for 1 minute
  CACHE_TIME_IMMUTABLE = 3600 # Cache blobs referred to by an immutable reference for 1 hour

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
    BlobViewer::OpenApi,

    BlobViewer::Image,
    BlobViewer::Sketch,
    BlobViewer::Balsamiq,

    BlobViewer::Video,
    BlobViewer::Audio,

    BlobViewer::PDF,

    BlobViewer::BinarySTL,
    BlobViewer::TextSTL
  ].sort_by { |v| v.binary? ? 0 : 1 }.freeze

  AUXILIARY_VIEWERS = [
    BlobViewer::GitlabCiYml,
    BlobViewer::RouteMap,

    BlobViewer::Readme,
    BlobViewer::License,
    BlobViewer::Contributing,
    BlobViewer::Changelog,

    BlobViewer::CargoToml,
    BlobViewer::Cartfile,
    BlobViewer::ComposerJson,
    BlobViewer::Gemfile,
    BlobViewer::Gemspec,
    BlobViewer::GodepsJson,
    BlobViewer::PackageJson,
    BlobViewer::Podfile,
    BlobViewer::Podspec,
    BlobViewer::PodspecJson,
    BlobViewer::RequirementsTxt,
    BlobViewer::YarnLock
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

  def self.lazy(project, commit_id, path)
    BatchLoader.for([commit_id, path]).batch(key: project.repository) do |items, loader, args|
      args[:key].blobs_at(items).each do |blob|
        loader.call([blob.commit_id, blob.path], blob) if blob
      end
    end
  end

  def initialize(blob, project = nil)
    @project = project

    super(blob)
  end

  def inspect
    "#<#{self.class.name} oid:#{id[0..8]} commit:#{commit_id[0..8]} path:#{path}>"
  end

  # Returns the data of the blob.
  #
  # If the blob is a text based blob the content is converted to UTF-8 and any
  # invalid byte sequences are replaced.
  def data
    if binary_in_repo?
      super
    else
      @data ||= super.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end
  end

  def load_all_data!
    # Endpoint needed: https://gitlab.com/gitlab-org/gitaly/issues/756
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      super(project.repository) if project
    end
  end

  def empty?
    raw_size == 0
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
  def binary?
    if stored_externally?
      if rich_viewer
        rich_viewer.binary?
      elsif known_extension?
        false
      elsif _mime_type
        _mime_type.binary?
      else
        true
      end
    else
      binary_in_repo?
    end
  end

  def extension
    @extension ||= extname.downcase.delete('.')
  end

  def file_type
    name = File.basename(path)

    Gitlab::FileDetector.type_of(path) || Gitlab::FileDetector.type_of(name)
  end

  def video?
    UploaderHelper::SAFE_VIDEO_EXT.include?(extension)
  end

  def audio?
    UploaderHelper::SAFE_AUDIO_EXT.include?(extension)
  end

  def readable_text?
    text_in_repo? && !stored_externally? && !truncated?
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
    simple_viewer.is_a?(BlobViewer::Text) && (ignore_errors || simple_viewer.render_error.nil?)
  end

  def show_viewer_switcher?
    rendered_as_text? && rich_viewer
  end

  def expanded?
    !!@expanded
  end

  def expand!
    @expanded = true
  end

  private

  def simple_viewer_class
    if empty?
      BlobViewer::Empty
    elsif binary?
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

Blob.prepend_if_ee('EE::Blob')
