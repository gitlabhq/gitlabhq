# frozen_string_literal: true

def storage_validation_error(message)
  raise "#{message}. Please fix this in your gitlab.yml before starting GitLab."
end

def validate_storages_config
  if Gitlab.config.repositories.storages.empty?
    storage_validation_error('No repository storage path defined')
  end

  Gitlab.config.repositories.storages.keys.each do |name|
    unless /\A[a-zA-Z0-9\-_.]+\z/.match?(name)
      storage_validation_error("\"#{name}\" is not a valid storage name")
    end
  end
end

validate_storages_config
