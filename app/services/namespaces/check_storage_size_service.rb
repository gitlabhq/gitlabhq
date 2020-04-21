# frozen_string_literal: true

module Namespaces
  class CheckStorageSizeService
    include ActiveSupport::NumberHelper

    def initialize(namespace)
      @root_namespace = namespace.root_ancestor
      @root_storage_size = Namespace::RootStorageSize.new(root_namespace)
    end

    def execute
      return ServiceResponse.success unless Feature.enabled?(:namespace_storage_limit, root_namespace)
      return ServiceResponse.success unless root_storage_size.show_alert?

      if root_storage_size.above_size_limit?
        ServiceResponse.error(message: above_size_limit_message, payload: payload)
      else
        ServiceResponse.success(message: info_message, payload: payload)
      end
    end

    private

    attr_reader :root_namespace, :root_storage_size

    def payload
      {
        current_usage_message: current_usage_message,
        usage_ratio: root_storage_size.usage_ratio
      }
    end

    def current_usage_message
      params = {
        usage_in_percent: number_to_percentage(root_storage_size.usage_ratio * 100, precision: 0),
        namespace_name: root_namespace.name,
        used_storage: formatted(root_storage_size.current_size),
        storage_limit: formatted(root_storage_size.limit)
      }
      s_("You reached %{usage_in_percent} of %{namespace_name}'s capacity (%{used_storage} of %{storage_limit})" % params)
    end

    def info_message
      s_("If you reach 100%% storage capacity, you will not be able to: %{base_message}" % { base_message: base_message } )
    end

    def above_size_limit_message
      s_("%{namespace_name} is now read-only. You cannot: %{base_message}" % { namespace_name: root_namespace.name, base_message: base_message })
    end

    def base_message
      s_("push to your repository, create pipelines, create issues or add comments. To reduce storage capacity, delete unused repositories, artifacts, wikis, issues, and pipelines.")
    end

    def formatted(number)
      number_to_human_size(number, delimiter: ',', precision: 2)
    end
  end
end
