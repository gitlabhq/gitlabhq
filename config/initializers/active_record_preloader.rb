module ActiveRecord
  module Associations
    class Preloader
      module NoCommitPreloader
        def preloader_for(reflection, owners, rhs_klass)
          return NullPreloader if rhs_klass == ::Commit

          super
        end
      end

      prepend NoCommitPreloader
    end
  end
end


class ActiveRecord::Associations::Preloader::Association
  def build_scope
    scope = klass.unscoped

    values         = reflection_scope.values
    reflection_binds = reflection_scope.bind_values
    preload_values = preload_scope.values
    preload_binds  = preload_scope.bind_values

    scope.where_values      = Array(values[:where])      + Array(preload_values[:where])
    scope.references_values = Array(values[:references]) + Array(preload_values[:references])
    scope.bind_values       = (reflection_binds + preload_binds)

    scope._select!   preload_values[:select] || values[:select] || table[Arel.star]
    scope.includes! preload_values[:includes] || values[:includes]
    scope.joins! preload_values[:joins] || values[:joins]
    scope.order! preload_values[:order] || values[:order]

    if preload_values[:reordering] || values[:reordering]
      scope.reordering_value = true
    end

    if preload_values[:readonly] || values[:readonly]
      scope.readonly!
    end

    if options[:as]
      scope.where!(klass.table_name => { reflection.type => model.base_class.sti_name })
    end

    # ADDED BELOW
    if from = preload_values[:from] || values[:from]
      scope.from!(*from)
    end
    # ADDED ABOVE

    scope.unscope_values = Array(values[:unscope]) + Array(preload_values[:unscope])
    klass.default_scoped.merge(scope)
  end
end
