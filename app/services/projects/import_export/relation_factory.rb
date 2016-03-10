module Projects
  module ImportExport
    class RelationFactory

      OVERRIDES = { snippets: :project_snippets }

      def self.create(*args)
        new(*args).create
      end

      def initialize(relation_sym:, relation_hash:, project:, user:)
        @relation_sym = parsed_relation_sym(relation_sym)
        @relation_hash = relation_hash
        @project = project
        @user = user
      end

      def create
        @relation_hash.delete('id')
        init_service_or_class
      end

      private

      def init_service_or_class
        # Attempt service first
        relation_service.new(@project, @user, @relation_hash).execute
      rescue NameError
        relation_class.new(@relation_hash)
      end

      def relation_service
        "#{@relation_sym.to_s.classify}::CreateService".constantize
      end

      def relation_class
        @relation_sym.to_s.classify.constantize
      end

      def parsed_relation_sym(relation_sym)
        OVERRIDES[relation_sym] || relation_sym
      end
    end
  end
end
