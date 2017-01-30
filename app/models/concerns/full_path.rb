module FullPath
  extend ActiveSupport::Concern
  extend CacheMethod::ClassMethods
  include CacheMethod

  included do
    before_save :expire_path_cache, if: :full_path_changed?
    cache_method :full_path
  end

  def full_path
    if parent && path
      parent.full_path + '/' + path
    else
      path
    end
  end

  def full_path_changed?
    path_changed? || parent_changed?
  end

  def expire_path_cache
    expire_method_caches(%w(full_path))
  end
end
