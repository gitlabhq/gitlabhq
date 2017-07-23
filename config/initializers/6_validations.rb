def storage_name_valid?(name)
  !!(name =~ /\A[a-zA-Z0-9\-_]+\z/)
end

def find_parent_path(name, path)
  parent = Pathname.new(path).realpath.parent
  Gitlab.config.repositories.storages.detect do |n, rs|
    name != n && Pathname.new(rs['path']).realpath == parent
  end
end

def storage_validation_error(message)
  raise "#{message}. Please fix this in your gitlab.yml before starting GitLab."
end

def validate_storages_config
  storage_validation_error('No repository storage path defined') if Gitlab.config.repositories.storages.empty?

  Gitlab.config.repositories.storages.each do |name, repository_storage|
    storage_validation_error("\"#{name}\" is not a valid storage name") unless storage_name_valid?(name)

    if repository_storage.is_a?(String)
      raise "#{name} is not a valid storage, because it has no `path` key. " \
        "It may be configured as:\n\n#{name}:\n  path: #{repository_storage}\n\n" \
        "For source installations, update your config/gitlab.yml Refer to gitlab.yml.example for an updated example.\n\n" \
        "If you're using the Gitlab Development Kit, you can update your configuration running `gdk reconfigure`.\n"
    end

    if !repository_storage.is_a?(Hash) || repository_storage['path'].nil?
      storage_validation_error("#{name} is not a valid storage, because it has no `path` key. Refer to gitlab.yml.example for an updated example")
    end
  end
end

def validate_storages_paths
  Gitlab.config.repositories.storages.each do |name, repository_storage|
    parent_name, _parent_path = find_parent_path(name, repository_storage['path'])
    if parent_name
      storage_validation_error("#{name} is a nested path of #{parent_name}. Nested paths are not supported for repository storages")
    end
  end
end

validate_storages_config
validate_storages_paths unless Rails.env.test? || ENV['SKIP_STORAGE_VALIDATION'] == 'true'
