# frozen_string_literal: true

# Including the `UnnestedInFilters::Dsl` module to an ActiveRecord
# model extends the interface of the following class instances to be
# able to use the `use_unnested_filters` method;
#
#   - Model relation;
#     `Model.where(...).use_unnested_filters`
#   - All the association proxies
#     `project.model_association.use_unnested_filters`
#   - All the relation instances of the association
#     `project.model_association.where(...).use_unnested_filters
#
# Note: The interface of the model itself won't be extended as we don't
# have a use-case for now(`Model.use_unnested_filters` won't work).
#
# Example usage of the API;
#
#   relation = Vulnerabilities::Read.where(state: [1, 4])
#                                   .use_unnested_filters
#                                   .order(severity: :desc, vulnerability_id: :desc)
#
#   relation.to_a # => Will load records by using the optimized query
#
# See `UnnestedInFilters::Rewriter` for the details about the optimizations applied.
#
# rubocop:disable Gitlab/ModuleWithInstanceVariables
module UnnestedInFilters
  module Dsl
    extend ActiveSupport::Concern

    MODULES_TO_EXTEND = [
      ActiveRecord::Relation,
      ActiveRecord::Associations::CollectionProxy,
      ActiveRecord::AssociationRelation
    ].freeze

    included do
      MODULES_TO_EXTEND.each do |mod|
        delegate_mod = relation_delegate_class(mod)
        delegate_mod.prepend(UnnestedInFilters::Dsl::Relation)
      end
    end

    module Relation
      def use_unnested_filters
        spawn.use_unnested_filters!
      end

      def use_unnested_filters!
        assert_mutability!
        @values[:unnested_filters] = true

        self
      end

      def use_unnested_filters?
        @values.fetch(:unnested_filters, false)
      end

      def load(*)
        return super if loaded? || !rewrite_query?

        @records = unnested_filter_rewriter.rewrite.to_a
        @loaded = true

        self
      end

      def exists?(*)
        return super unless rewrite_query?

        unnested_filter_rewriter.rewrite.exists?
      end

      private

      def rewrite_query?
        use_unnested_filters? && unnested_filter_rewriter.rewrite?
      end

      def unnested_filter_rewriter
        @unnested_filter_rewriter ||= UnnestedInFilters::Rewriter.new(self)
      end
    end
  end
end
