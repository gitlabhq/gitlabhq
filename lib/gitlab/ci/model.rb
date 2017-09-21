module Gitlab
  module Ci
    module Model
      def table_name_prefix
        "ci_"
      end

      def model_name
        @model_name ||= ActiveModel::Name.new(self, nil, self.name.split("::").last)
      end
    end
  end
end
