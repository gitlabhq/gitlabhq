# frozen_string_literal: true

module CrudPolicyHelpers
  extend ActiveSupport::Concern

  class_methods do
    def create_read_update_admin_destroy(name)
      [
        :"read_#{name}",
        *create_update_admin_destroy(name)
      ]
    end

    def create_update_admin_destroy(name)
      [
        *create_update_admin(name),
        :"destroy_#{name}"
      ]
    end

    def create_update_admin(name)
      [
        :"create_#{name}",
        :"update_#{name}",
        :"admin_#{name}"
      ]
    end
  end
end
