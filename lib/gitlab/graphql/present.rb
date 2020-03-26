# frozen_string_literal: true

module Gitlab
  module Graphql
    module Present
      extend ActiveSupport::Concern
      prepended do
        def self.present_using(kls)
          @presenter_class = kls
        end

        def self.presenter_class
          @presenter_class
        end
      end

      def self.use(schema_definition)
        schema_definition.instrument(:field, ::Gitlab::Graphql::Present::Instrumentation.new)
      end
    end
  end
end
