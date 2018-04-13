class ProjectPolicy
  module ClassMethods
    def create_read_update_admin_destroy(name)
      [
        :"read_#{name}",
        *create_update_admin_destroy(name)
      ]
    end

    def create_update_admin_destroy(name)
      [
        :"create_#{name}",
        :"update_#{name}",
        :"admin_#{name}",
        :"destroy_#{name}"
      ]
    end
  end
end
