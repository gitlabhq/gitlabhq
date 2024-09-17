# frozen_string_literal: true

# rubocop:disable CodeReuse/ActiveRecord
module ClickHouse
  class QueryBuilder < ClickHouse::Client::QueryLike
    attr_reader :table
    attr_accessor :conditions, :manager

    VALID_NODES = [
      Arel::Nodes::In,
      Arel::Nodes::Equality,
      Arel::Nodes::LessThan,
      Arel::Nodes::LessThanOrEqual,
      Arel::Nodes::GreaterThan,
      Arel::Nodes::GreaterThanOrEqual
    ].freeze

    def initialize(table_name)
      @table = Arel::Table.new(table_name)
      @manager = Arel::SelectManager.new(Arel::Table.engine).from(@table).project(Arel.star)
      @conditions = []
    end

    # The `where` method currently does only supports IN and equal to queries along
    # with above listed VALID_NODES.
    # For example, using a range (start_date..end_date) will result in incorrect SQL.
    # If you need to query a range, use greater than and less than conditions with Arel.
    #
    # Correct usage:
    #   query.where(query.table[:created_at].lteq(Date.today)).to_sql
    #   "SELECT * FROM \"table\" WHERE \"table\".\"created_at\" <= '2023-08-01'"
    #
    # This also supports array conditions which will result in an IN query.
    #   query.where(entity_id: [1,2,3]).to_sql
    #   "SELECT * FROM \"table\" WHERE \"table\".\"entity_id\" IN (1, 2, 3)"
    #
    # Range support and more `Arel::Nodes` could be considered for future iterations.
    # @return [ClickHouse::QueryBuilder] New instance of query builder.
    def where(conditions)
      validate_condition_type!(conditions)

      new_instance = deep_clone

      if conditions.is_a?(Arel::Nodes::Node)
        new_instance.conditions << conditions
      else
        add_conditions_to(new_instance, conditions)
      end

      new_instance
    end

    def select(*fields)
      new_instance = deep_clone

      existing_fields = new_instance.manager.projections.filter_map do |projection|
        if projection.is_a?(Arel::Attributes::Attribute)
          projection.name.to_s
        elsif projection.to_s == '*'
          nil
        end
      end

      new_projections = (existing_fields + fields).map do |field|
        if field.is_a?(Symbol)
          field.to_s
        else
          field
        end
      end

      new_instance.manager.projections = new_projections.uniq.map do |field|
        if field.is_a?(Arel::Expressions)
          field
        else
          new_instance.table[field.to_s]
        end
      end
      new_instance
    end

    def order(field, direction = :asc)
      validate_order_direction!(direction)

      new_instance = deep_clone

      new_order = new_instance.table[field].public_send(direction.to_s.downcase) # rubocop:disable GitlabSecurity/PublicSend
      new_instance.manager.order(new_order)

      new_instance
    end

    def group(*columns)
      new_instance = deep_clone

      new_instance.manager.group(*columns)

      new_instance
    end

    def limit(count)
      manager.take(count)
      self
    end

    def offset(count)
      manager.skip(count)
      self
    end

    def to_sql
      apply_conditions!
      manager.to_sql
    end

    def to_redacted_sql(bind_index_manager = ClickHouse::Client::BindIndexManager.new)
      ::ClickHouse::Redactor.redact(self, bind_index_manager)
    end

    private

    def validate_condition_type!(condition)
      return unless condition.is_a?(Arel::Nodes::Node) && VALID_NODES.exclude?(condition.class)

      raise ArgumentError, "Unsupported Arel node type for QueryBuilder: #{condition.class.name}"
    end

    def add_conditions_to(instance, conditions)
      conditions.each do |key, value|
        instance.conditions << if value.is_a?(Array)
                                 instance.table[key].in(value)
                               else
                                 instance.table[key].eq(value)
                               end
      end
    end

    def deep_clone
      new_instance = self.class.new(table.name)
      new_instance.manager = manager.clone
      new_instance.conditions = conditions.map(&:clone)
      new_instance
    end

    def apply_conditions!
      manager.constraints.clear
      conditions.each { |condition| manager.where(condition) }
    end

    def validate_order_direction!(direction)
      return if %w[asc desc].include?(direction.to_s.downcase)

      raise ArgumentError, "Invalid order direction '#{direction}'. Must be :asc or :desc"
    end
  end
end
# rubocop:enable CodeReuse/ActiveRecord
