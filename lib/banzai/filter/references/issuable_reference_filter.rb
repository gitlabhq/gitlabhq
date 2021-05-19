# frozen_string_literal: true

module Banzai
  module Filter
    module References
      class IssuableReferenceFilter < AbstractReferenceFilter
        def record_identifier(record)
          record.iid.to_i
        end

        def find_object(parent, iid)
          reference_cache.records_per_parent[parent][iid]
        end
      end
    end
  end
end
