module Banzai
  module Filter
    class IssuableReferenceFilter < AbstractReferenceFilter
      def records_per_parent
        @records_per_project ||= {}

        @records_per_project[object_class.to_s.underscore] ||= begin
          hash = Hash.new { |h, k| h[k] = {} }

          parent_per_reference.each do |path, parent|
            record_ids = references_per_parent[path]

            parent_records(parent, record_ids).each do |record|
              hash[parent][record.iid.to_i] = record
            end
          end

          hash
        end
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
