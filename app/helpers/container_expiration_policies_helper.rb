# frozen_string_literal: true

module ContainerExpirationPoliciesHelper
  def cadence_options
    ContainerExpirationPolicy.cadence_options.map do |key, val|
      { key: key.to_s, label: val }.tap do |base|
        base[:default] = true if key.to_s == '1d'
      end
    end
  end

  def keep_n_options
    ContainerExpirationPolicy.keep_n_options.map do |key, val|
      { key: key, label: val }.tap do |base|
        base[:default] = true if key == 10
      end
    end
  end

  def older_than_options
    ContainerExpirationPolicy.older_than_options.map do |key, val|
      { key: key.to_s, label: val }.tap do |base|
        base[:default] = true if key.to_s == '90d'
      end
    end
  end

  def container_expiration_policies_historic_entry_enabled?
    Gitlab::CurrentSettings.container_expiration_policies_enable_historic_entries
  end
end
