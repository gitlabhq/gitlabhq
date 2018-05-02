# This is a monkey patch which must be removed when migrating to Rails 5.1 from 5.0.
#
# In Rails 5.0 there was introduced a bug which casts types in the uniqueness validator.
# https://github.com/rails/rails/pull/23523/commits/811a4fa8eb6ceea841e61e8ac05747ffb69595ae
#
# That causes to bugs like this:
#
#     1) API::Users POST /user/:id/gpg_keys/:key_id/revoke when authenticated revokes existing key
#     Failure/Error: let(:gpg_key) { create(:gpg_key, user: user) }
#
#     TypeError:
#       can't cast Hash
#     # ./spec/requests/api/users_spec.rb:7:in `block (2 levels) in <top (required)>'
#     # ./spec/requests/api/users_spec.rb:908:in `block (4 levels) in <top (required)>'
#     # ------------------
#     # --- Caused by: ---
#     # TypeError:
#     #   TypeError
#     #   ./spec/requests/api/users_spec.rb:7:in `block (2 levels) in <top (required)>'
#
# This bug was fixed in Rails 5.1 by https://github.com/rails/rails/pull/24745/commits/aa062318c451512035c10898a1af95943b1a3803

if Gitlab.rails5?
  ActiveSupport::Deprecation.warn("#{__FILE__} is a monkey patch which must be removed when upgrading to Rails 5.1")

  if Rails.version.start_with?("5.1")
    raise "Remove this monkey patch: #{__FILE__}"
  end

  # Copy-paste from https://github.com/kamipo/rails/blob/aa062318c451512035c10898a1af95943b1a3803/activerecord/lib/active_record/validations/uniqueness.rb
  # including local fixes to make Rubocop happy again.
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

          comparison =
            if !options[:case_sensitive] && !value.nil?
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
end
