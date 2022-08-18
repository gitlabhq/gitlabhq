# frozen_string_literal: true

module Gitlab
  module ImportExport
    class LogUtil
      def self.exportable_to_log_payload(exportable)
        attribute_base_name = exportable.class.name.underscore

        return {} unless %w[project group].include?(attribute_base_name)

        {}.tap do |log|
          log[:"#{attribute_base_name}_id"] = exportable.id
          log[:"#{attribute_base_name}_name"] = exportable.name
          log[:"#{attribute_base_name}_path"] = exportable.full_path
        end.compact
      end
    end
  end
end
