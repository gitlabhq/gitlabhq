def storage_name_valid?(name)
  !!(name =~ /\A[a-zA-Z0-9\-_]+\z/)
end

def storage_validation_error(message)
  raise "#{message}. Please fix this in your gitlab.yml before starting GitLab."
end

def validate_storages_config
  storage_validation_error('No repository storage path defined') if Gitlab.config.repositories.storages.empty?

  Gitlab.config.repositories.storages.each do |name, repository_storage|
    storage_validation_error("\"#{name}\" is not a valid storage name") unless storage_name_valid?(name)

    %w(failure_count_threshold failure_reset_time storage_timeout).each do |setting|
      # Falling back to the defaults is fine!
      next if repository_storage[setting].nil?

      unless repository_storage[setting].to_f > 0
        storage_validation_error("`#{setting}` for storage `#{name}` needs to be greater than 0")
      end
    end
  end
end

validate_storages_config
