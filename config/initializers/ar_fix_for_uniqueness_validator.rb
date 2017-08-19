## In rails 5.0 they added a type casting to uniqueness validator
# https://github.com/rails/rails/blob/5-0-stable/activerecord/lib/active_record/validations/uniqueness.rb#L68-L69
# Which caused double type casting. Which is a bug.
# Although nobody reported this bug, they fixed it in rails 5.1 https://github.com/rails/rails/pull/24745/files
# see details https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12841#note_37975258

# This particular patch just applies the fix which should be removed when we are on rails 5.1 and above

if Rails.version.start_with?('5.1')
  raise 'Please remove this file'
end

module ActiveRecord
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator # :nodoc:
      def validate_each(record, attribute, value)
        finder_class = find_finder_class_for(record)
        table = finder_class.arel_table
        value = map_enum_attribute(finder_class, attribute, value)

        relation = build_relation(finder_class, table, attribute, value)
        if record.persisted?
          if finder_class.primary_key
            relation = relation.where.not(finder_class.primary_key => record.id_was || record.id)
          else
            raise UnknownPrimaryKey.new(finder_class, "Can not validate uniqueness for persisted record without primary key.")
          end
        end
        relation = scope_relation(record, table, relation)
        relation = relation.merge(options[:conditions]) if options[:conditions]

        if relation.exists?
          error_options = options.except(:case_sensitive, :scope, :conditions)
          error_options[:value] = value

          record.errors.add(attribute, :taken, error_options)
        end
        rescue RangeError
      end

    protected
      def build_relation(klass, table, attribute, value) #:nodoc:
        if reflection = klass._reflect_on_association(attribute)
          attribute = reflection.foreign_key
          value = value.attributes[reflection.klass.primary_key] unless value.nil?
        end

        # the attribute may be an aliased attribute
        if klass.attribute_alias?(attribute)
          attribute = klass.attribute_alias(attribute)
        end

        attribute_name = attribute.to_s

        column = klass.columns_hash[attribute_name]
        cast_type = klass.type_for_attribute(attribute_name)

        comparison = if !options[:case_sensitive] && !value.nil?
          # will use SQL LOWER function before comparison, unless it detects a case insensitive collation
          klass.connection.case_insensitive_comparison(table, attribute, column, value)
        else
          klass.connection.case_sensitive_comparison(table, attribute, column, value)
        end
        if value.nil?
          klass.unscoped.where(comparison)
        else
          bind = Relation::QueryAttribute.new(attribute_name, value, cast_type)
          klass.unscoped.where(comparison, bind)
        end
      end
    end
  end
end
