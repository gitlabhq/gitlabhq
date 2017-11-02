module ClusterApp
  extend ActiveSupport::Concern

  included do
    def find_app(app_name, id)
      Clusters::Applications.const_get(app_name.classify).find(id).try do |app|
        yield(app) if block_given?
      end
    end
  end
end
