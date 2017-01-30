module FullName
  extend ActiveSupport::Concern
  extend CacheMethod::ClassMethods
  include CacheMethod

  included do
    before_save :expire_name_cache, if: :full_name_changed?
    cache_method :full_name
  end

  def full_name
    if parent
      parent.human_name + ' / ' + name
    else
      name
    end
  end

  def full_name_changed?
    name_changed? || parent_changed?
  end

  def expire_name_cache
    expire_method_caches(%w(full_name))
  end
end
