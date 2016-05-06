module Gitlab
  module ImportExport
    module ImportExportReader
      extend self

      def project_tree
        { only: included_attributes[:project], include: build_hash(tree) }
      end

      def tree
        config[:project_tree]
      end

      private

      def config
        @config ||= YAML.load_file('lib/gitlab/import_export/import_export.yml').with_indifferent_access
      end

      def included_attributes
        config[:included_attributes] || {}
      end

      def excluded_attributes
        config[:excluded_attributes] || {}
      end

      def build_hash(array)
        array.map do |model_object|
          if model_object.is_a?(Hash)
            process_include(model_object)
          else
            only_except_hash = check_only_and_except(model_object)
            only_except_hash.empty? ? model_object : { model_object => only_except_hash }
          end
        end
      end

      def process_include(hash, included_classes_hash = {})
        hash.values.flatten.each do |value|
          current_key = hash.keys.first
          value = process_current_class(hash, included_classes_hash, value)
          if included_classes_hash[current_key]
            add_to_class(current_key, included_classes_hash, value)
          else
            add_new_class(current_key, included_classes_hash, value)
          end
        end
        included_classes_hash
      end

      def process_current_class(hash, included_classes_hash, value)
        value = value.is_a?(Hash) ? process_include(hash, included_classes_hash) : value
        only_except_hash = check_only_and_except(hash.keys.first)
        included_classes_hash[hash.keys.first] ||= only_except_hash unless only_except_hash.empty?
        value
      end

      def add_new_class(current_key, included_classes_hash, value)
        only_except_hash = check_only_and_except(value)
        parsed_hash = { include: value }
        unless only_except_hash.empty?
          if value.is_a?(Hash)
            parsed_hash = { include: value.merge(only_except_hash) }
          else
            parsed_hash = { include: { value => only_except_hash } }
          end
        end
        included_classes_hash[current_key] = parsed_hash
      end

      def add_to_class(current_key, included_classes_hash, value)
        only_except_hash = check_only_and_except(value)
        value = { value => only_except_hash } unless only_except_hash.empty?
        old_values = included_classes_hash[current_key][:include]
        included_classes_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end

      def check_only_and_except(value)
        check_only(value).merge(check_except(value))
      end

      def check_only(value)
        key = key_from_hash(value)
        included_attributes[key].nil? ? {} : { only: included_attributes[key] }
      end

      def check_except(value)
        key = key_from_hash(value)
        excluded_attributes[key].nil? ? {} : { except: excluded_attributes[key] }
      end

      def key_from_hash(value)
        value.is_a?(Hash) ? value.keys.first : value
      end
    end
  end
end
