# frozen_string_literal: true

module EnumInheritance
  # == STI through Enum
  #
  # WARNING: Usage of STI is heavily discouraged: https://docs.gitlab.com/ee/development/database/single_table_inheritance.html
  #
  # Active Record allows definition of STI through the <tt>Base.inheritance_column</tt>. However, this stores the class
  # name as string into the record, which is heavy and unnecessary. EnumInheritance adapts ActiveRecord to use an enum
  # instead.
  #
  # Details:
  # - Correct class mapping is specified in the <tt>self.sti_type_map<\tt>, which maps the symbol of the type to
  # a fully classified class as string.
  # - If the type passed does not have an specified class, then the class will be the base class
  #
  # Example
  #   class Animal
  #     include EnumInheritable
  #
  #     enum animal_type: {
  #       dog: 1,
  #       cat: 2,
  #       bird: 3
  #     }
  #
  #     def self.inheritance_column_to_class_map = {
  #       dog: 'Animals::Dog',
  #       cat: 'Animals::Cat'
  #     }
  #
  #     def self.inheritance_column = 'animal_type'
  #   end
  #
  #   class Animals::Dog < Animal; end
  #   class Animals::Cat < Animal; end
  extend ActiveSupport::Concern

  included do
    def self.sti_class_to_enum_map = inheritance_column_to_class_map.invert
  end

  class_methods do
    extend ::Gitlab::Utils::Override

    def inheritance_column_to_class_map = {}.freeze

    override :sti_class_for
    def sti_class_for(type_name)
      inheritance_column_to_class_map[type_name.to_sym]&.constantize || base_class
    end

    override :sti_name
    def sti_name
      sti_class_to_enum_map[name].to_s
    end
  end
end
