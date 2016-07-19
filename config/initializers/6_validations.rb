def storage_name_valid?(name)
  !!(name =~ /\A[a-zA-Z0-9\-_]+\z/)
end

def find_parent_path(name, path)
  Gitlab.config.repositories.storages.detect do |n, p|
    name != n && path.chomp('/').start_with?(p.chomp('/'))
  end
end

def error(message)
  raise "#{message}. Please fix this in your gitlab.yml before starting GitLab."
end

error('No repository storage path defined') if Gitlab.config.repositories.storages.empty?

Gitlab.config.repositories.storages.each do |name, path|
  error("\"#{name}\" is not a valid storage name") unless storage_name_valid?(name)

  parent_name, _parent_path = find_parent_path(name, path)
  if parent_name
    error("#{name} is a nested path of #{parent_name}. Nested paths are not supported for repository storages")
  end
end
