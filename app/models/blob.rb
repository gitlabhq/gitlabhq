# Blob is a Rails-specific wrapper around Gitlab::Git::Blob objects
class Blob < SimpleDelegator
  CACHE_TIME = 60 # Cache raw blobs referred to by a (mutable) ref for 1 minute
  CACHE_TIME_IMMUTABLE = 3600 # Cache blobs referred to by an immutable reference for 1 hour

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
  def self.decorate(blob)
    return if blob.nil?

    new(blob)
  end

  def no_highlighting?
    size && size > 1.megabyte
  end

  def only_display_raw?
    size && truncated?
  end

  def svg?
    text? && language && language.name == 'SVG'
  end

  def video?
    UploaderHelper::VIDEO_EXT.include?(extname.downcase.delete('.'))
  end

  def to_partial_path
    if lfs_pointer?
      'download'
    elsif image? || svg?
      'image'
    elsif text?
      'text'
    else
      'download'
    end
  end
end
