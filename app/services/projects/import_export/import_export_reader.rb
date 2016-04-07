module Projects
  module ImportExport
    module ImportExportReader
      extend self

      def project_tree
        { only: atts_only[:project], include: build_hash(tree) }
      end

      private

      def config
        @config ||= YAML.load_file('app/services/projects/import_export/import_export.yml')
      end

      def atts_only
        config[:attributes_only]
      end

      def atts_except
        config[:attributes_except]
      end

      def tree
        config[:project_tree]
      end

      def build_hash(array)
        array.map { |el| el.is_a?(Hash) ? process_include(el) : el }
      end

      def process_include(hash, included_classes_hash = {})
        hash.values.flatten.each do |value|
          current_key, value = process_current_class(hash, included_classes_hash, value)
          if included_classes_hash[current_key]
            add_class(current_key, included_classes_hash, value)
          else
            add_new_class(current_key, included_classes_hash, value)
          end
        end
        included_classes_hash
      end

      def process_current_class(hash, included_classes_hash, value)
        value = value.is_a?(Hash) ? process_include(hash, included_classes_hash) : value
        current_key = hash.keys.first
        current_key_only = check_only_and_except(current_key)
        included_classes_hash[current_key] ||= current_key_only unless current_key_only.empty?
        return current_key, value
      end

      def add_new_class(current_key, included_classes_hash, value)
        new_hash = { :include => value }
        new_hash.merge!(check_only_and_except(value))
        included_classes_hash[current_key] = new_hash
      end

      def add_class(current_key, included_classes_hash, value)
        check_only_hash = check_only_and_except(value)
        value = { value => check_only_hash } unless check_only_hash.empty?
        old_values = included_classes_hash[current_key][:include]
        included_classes_hash[current_key][:include] = ([old_values] + [value]).compact.flatten
      end

      def check_only_and_except(value)
        check_only(value).merge(check_except(value))
      end

      def check_only(value)
        key = key_from_hash(value)
        atts_only[key].nil? ? {} : { only: atts_only[key] }
      end

      def check_except(value)
        key = key_from_hash(value)
        atts_except[key].nil? ? {} : { except: atts_except[key] }
      end

      def key_from_hash(value)
        value.is_a?(Hash) ? value.keys.first : value
      end
    end
  end
end