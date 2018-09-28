module Gitlab
  module ImportExport
    class Reader
      attr_reader :tree, :attributes_finder

      def initialize(shared:)
        @shared = shared
        config_hash = YAML.load_file(Gitlab::ImportExport.config_file).deep_symbolize_keys
        @tree = config_hash[:project_tree]
        @attributes_finder = Gitlab::ImportExport::AttributesFinder.new(included_attributes: config_hash[:included_attributes],
                                                                        excluded_attributes: config_hash[:excluded_attributes],
                                                                        methods: config_hash[:methods])
      end

      # Outputs a hash in the format described here: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
      # for outputting a project in JSON format, including its relations and sub relations.
      def project_tree
        attributes = @attributes_finder.find(:project)
        project_attributes = attributes.is_a?(Hash) ? attributes[:project] : {}

        project_attributes.merge(include: build_hash(@tree))
      rescue => e
        @shared.error(e)
        false
      end

      def group_members_tree
        @attributes_finder.find_included(:project_members).merge(include: @attributes_finder.find(:user))
      end

      private

      # Builds a hash in the format described here: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
      #
      # +model_list+ - List of models as a relation tree to be included in the generated JSON, from the _import_export.yml_ file
      def build_hash(model_list)
        model_list.map do |model_objects|
          if model_objects.is_a?(Hash)
            Gitlab::ImportExport::JsonHashBuilder.build(model_objects, @attributes_finder)
          else
            @attributes_finder.find(model_objects)
          end
        end
      end
    end
  end
end
