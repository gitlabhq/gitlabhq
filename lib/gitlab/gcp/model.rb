module Gitlab
  module Gcp
    module Model
      def table_name_prefix
        "gcp_"
      end

      def model_name
        @model_name ||= ActiveModel::Name.new(self, nil, self.name.split("::").last)
      end
    end
  end
end
