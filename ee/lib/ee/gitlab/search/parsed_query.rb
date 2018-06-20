module EE
  module Gitlab
    module Search
      module ParsedQuery
        def elasticsearch_filters(object)
          filters.map do |filter|
            prepare_for_elasticsearch(object, filter)
          end
        end

        private

        def prepare_for_elasticsearch(object, filter)
          type = filter[:type] || :wildcard
          field = filter[:field] || filter[:name]

          {
            type => {
              "#{object}.#{field}" => filter[:value]
            }
          }
        end
      end
    end
  end
end
