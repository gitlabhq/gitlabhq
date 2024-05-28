# frozen_string_literal: true

module ServicePing
  class BuildPayload
    def execute
      filtered_usage_data
    end

    private

    def raw_payload
      @raw_payload ||= ::Gitlab::Usage::ServicePingReport.for(output: :all_metrics_values)
    end

    def filtered_usage_data(payload = raw_payload, parents = [])
      return unless payload.is_a?(Hash)

      payload.keep_if do |label, node|
        key_path = parents.dup.append(label).join('.')

        if has_metric_definition?(key_path)
          include_metric?(key_path)
        elsif node.is_a?(Hash)
          filtered_usage_data(node, parents.dup << label)
        end
      end
    end

    def include_metric?(key_path)
      valid_metric_status?(key_path) && permitted_metric?(key_path)
    end

    def valid_metric_status?(key_path)
      metric_definitions[key_path]&.valid_service_ping_status?
    end

    def permitted_categories
      @permitted_categories ||= ::ServicePing::PermitDataCategories.new.execute
    end

    def permitted_metric?(key_path)
      permitted_categories.include?(metric_category(key_path))
    end

    def has_metric_definition?(key_path)
      metric_definitions[key_path].present?
    end

    def metric_category(key_path)
      metric_definitions[key_path]&.data_category || ::ServicePing::PermitDataCategories::OPTIONAL_CATEGORY
    end

    def metric_definitions
      @metric_definitions ||= ::Gitlab::Usage::MetricDefinition.definitions
    end
  end
end

ServicePing::BuildPayload.prepend_mod_with('ServicePing::BuildPayload')
