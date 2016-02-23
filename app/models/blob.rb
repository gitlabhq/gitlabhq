# Blob is a Rails-specific wrapper around Gitlab::Git::Blob objects
class Blob < SimpleDelegator
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

  def svg?
    text? && language && language.name == 'SVG'
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
