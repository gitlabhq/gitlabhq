# frozen_string_literal: true

class Namespace::RootStorageSize
  def initialize(root_namespace)
    @root_namespace = root_namespace
  end

  def above_size_limit?
    return false if limit == 0

    usage_ratio > 1
  end

  def usage_ratio
    return 0 if limit == 0

    current_size.to_f / limit.to_f
  end

  def current_size
    @current_size ||= root_namespace.root_storage_statistics&.storage_size
  end

  def limit
    @limit ||= Gitlab::CurrentSettings.namespace_storage_size_limit.megabytes
  end

  private

  attr_reader :root_namespace
end
