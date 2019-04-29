# frozen_string_literal: true

module Gitlab
  module ImportExport
    class Config
      # Returns a Hash of the YAML file, including EE specific data if EE is
      # used.
      def to_h
        hash = parse_yaml
        ee_hash = hash['ee']

        if merge? && ee_hash
          ee_hash.each do |key, value|
            if key == 'project_tree'
              merge_project_tree(value, hash[key])
            else
              merge_attributes_list(value, hash[key])
            end
          end
        end

        # We don't want to expose this section after this point, as it is no
        # longer needed.
        hash.delete('ee')

        hash
      end

      # Merges a project relationships tree into the target tree.
      #
      # @param [Array<Hash|Symbol>] source_values
      # @param [Array<Hash|Symbol>] target_values
      def merge_project_tree(source_values, target_values)
        source_values.each do |value|
          if value.is_a?(Hash)
            # Examples:
            #
            # { 'project_tree' => [{ 'labels' => [...] }] }
            # { 'notes' => [:author, { 'events' => [:push_event_payload] }] }
            value.each do |key, val|
              target = target_values
                .find { |h| h.is_a?(Hash) && h[key] }

              if target
                merge_project_tree(val, target[key])
              else
                target_values << { key => val.dup }
              end
            end
          else
            # Example: :priorities, :author, etc
            target_values << value
          end
        end
      end

      # Merges a Hash containing a flat list of attributes, such as the entries
      # in a `excluded_attributes` section.
      #
      # @param [Hash] source_values
      # @param [Hash] target_values
      def merge_attributes_list(source_values, target_values)
        source_values.each do |key, values|
          target_values[key] ||= []
          target_values[key].concat(values)
        end
      end

      def merge?
        Gitlab.ee?
      end

      def parse_yaml
        YAML.load_file(Gitlab::ImportExport.config_file)
      end
    end
  end
end
