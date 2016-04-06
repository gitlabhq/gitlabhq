module Projects
  module ImportExport
    module ImportExportReader
      extend self

      def project_tree
        { only: atts_only[:project], include: build_hash(tree) }
      end

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

      def process_include(hash)
        included_classes_hash = {}
        hash.values.flatten.each do |value|
          value = value.is_a?(Hash) ? process_include(hash) : value
          new_hash = { :include => value }
          new_hash.merge!(check_only(value))
          included_classes_hash[hash.keys.first] = new_hash
        end
        included_classes_hash
      end

      def check_only(value)
        key = value.is_a?(Hash) ? value.keys.first : value
        atts_only[key].nil? ? {} : { only: atts_only[key] }
      end
    end
  end
end