# frozen_string_literal: true

# Adds support for WITH statements when using PostgreSQL. The code here is taken
# from https://github.com/shmay/ctes_in_my_pg which at the time of writing has
# not been pushed to RubyGems. The license of this repository is as follows:
#
# The MIT License (MIT)
#
# Copyright (c) 2012 Dan McClain
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module ActiveRecord
  class Relation
    class Merger # :nodoc:
      def normal_values
        NORMAL_VALUES + [:with]
      end
    end
  end
end

module ActiveRecord::Querying
  delegate :with, to: :all
end

# Rails 7.1 defines #with method.
# Therefore, this file can be either simplified or completely removed.
module ActiveRecord
  class Relation
    # WithChain objects act as placeholder for queries in which #with does not have any parameter.
    # In this case, #with must be chained with #recursive to return a new relation.
    class WithChain
      def initialize(scope)
        @scope = scope
      end

      # Returns a new relation expressing WITH RECURSIVE
      def recursive(*args)
        @scope.with_values_ += args
        @scope.recursive_value = true
        @scope.extend(Gitlab::Database::ReadOnlyRelation)
        @scope
      end
    end

    def with_values_
      @values[:with_values] || []
    end

    def with_values_=(values)
      raise ImmutableRelation if @loaded

      @values[:with_values] = values
    end

    def recursive_value=(value)
      raise ImmutableRelation if @loaded

      @values[:recursive] = value
    end

    def recursive_value
      @values[:recursive]
    end

    def with(opts = :chain, *rest)
      if opts == :chain
        WithChain.new(spawn)
      elsif opts.blank?
        self
      else
        spawn.with!(opts, *rest)
      end
    end

    def with!(opts = :chain, *rest) # :nodoc:
      if opts == :chain
        WithChain.new(self)
      else
        self.with_values_ += [opts] + rest
        self
      end
    end

    def build_arel(aliases = nil)
      arel = super

      build_with(arel) if @values[:with_values]

      arel
    end

    def build_with(arel)
      with_statements = with_values_.flat_map do |with_value|
        case with_value
        when String
          with_value
        when Hash
          with_value.map do |name, expression|
            case expression
            when String
              select = Arel::Nodes::SqlLiteral.new "(#{expression})"
            when ActiveRecord::Relation, Arel::SelectManager
              select = Arel::Nodes::SqlLiteral.new "(#{expression.to_sql})"
            end
            Arel::Nodes::As.new Arel::Nodes::SqlLiteral.new("\"#{name}\""), select
          end
        when Arel::Nodes::As
          with_value
        when Gitlab::Database::AsWithMaterialized
          with_value
        end
      end

      unless with_statements.empty?
        if recursive_value
          arel.with :recursive, with_statements
        else
          arel.with with_statements
        end
      end
    end
  end
end
