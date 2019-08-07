# frozen_string_literal: true

module Banzai
  module Filter
    class IssuableReferenceFilter < AbstractReferenceFilter
      def record_identifier(record)
        record.iid.to_i
      end

      def find_object(parent, iid)
        records_per_parent[parent][iid]
      end

      def parent_from_ref(ref)
        parent_per_reference[ref || current_parent_path]
      end
    end
  end
end
